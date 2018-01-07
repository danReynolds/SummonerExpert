require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
require "#{Rails.root}/lib/match_helper.rb"
require "#{Rails.root}/lib/datadog.rb"

include RiotApi
include ActionView::Helpers::SanitizeHelper

# The API limit is 500 requests every 10 seconds = 180000 every hour
# Leave a percentage of requests that can be run per hour for manual requests
# made by the client and testing
MATCH_BATCH_SIZE = 150000

# Use recent players to determine the new end match index
PLAYER_POOL_SIZE = 300

# Threshold used to determine if an outlier end match index was found. Generally
# there are < 100000 new games per ~1 hour so this indicates a large jump
END_MATCH_INDEX_THRESHOLD = 500000

namespace :champion_gg do
  task all: [:cache_champion_performance, :cache_site_information]

  # Cache how a champion does in matchups against other champs in that role
  def cache_champion_matchups(name, id, elo, matchup_data)
    ids_to_names = Cache.get_collection(:champions)

    matchup_data.to_a.each do |matchup_role, matchups|
      champion_matchups = {}

      matchups.each do |matchup|
        if id == matchup['champ1_id']
          other_id = matchup['champ2_id']
          other_name = ids_to_names[other_id]
          champion_matchups[other_name] = {}
          champion_matchups[other_name][name] = matchup['champ1']
          champion_matchups[other_name][other_name] = matchup['champ2']
        else
          other_id = matchup['champ1_id']
          other_name = ids_to_names[other_id]
          champion_matchups[other_name] = {}
          champion_matchups[other_name][name] = matchup['champ2']
          champion_matchups[other_name][other_name] = matchup['champ1']
        end
      end

      Cache.set_champion_matchups(
        name, ChampionGGApi::MATCHUP_ROLES[matchup_role.to_sym], elo,
        champion_matchups
      )
    end
  end

  # Cache the ranking lists for champion performance on metrics like kills,
  # etc in that role
  def cache_champion_rankings(champion_rankings, elo, ids_to_names)
    champion_rankings.each do |role, position_names|
      position_names.each do |position_name, champion_positions|
        ranked_champions = champion_positions.sort_by do |champion_position|
          champion_position[:position]
        end.map do |champion_position|
          ids_to_names[champion_position[:id]]
        end

        # An exception is made for the deaths ranking which is ranked by least
        # = best deaths unlike all other rankings which are in terms of most CS,
        # most # kills, etc. being equal to best. So if someone asks for the
        # person with most deaths, they want the worst ranked person so the list
        # is reversed.
        ranked_champions.reverse! if position_name == ChampionGGApi::POSITIONS[:deaths]
        Cache.set_champion_rankings(
          position_name, elo, ChampionGGApi::ROLES[role.to_sym], ranked_champions
        )
      end
    end
  end

  desc 'Cache general Champion.gg site information'
  task cache_site_information: :environment do
    information = ChampionGGApi::get_site_information
    Cache.set_patch(information.first['patch'])
  end

  desc 'Cache champion role and matchup performance'
  task cache_champion_performance: :environment do
    # Arbitrarily high enough number used for variable combinations of champions x roles
    champion_roles_limit = 10000

    ids_to_names = Cache.get_collection(:champions)

    ChampionGGApi::ELOS.values.each do |elo|
      champion_rankings = {}

      # Platinum plus should be sent as empty string since it is the default if
      # no elo is specified.
      champion_roles = if elo == ChampionGGApi::ELOS[:PLATINUM_PLUS]
        ChampionGGApi::get_champion_roles(limit: champion_roles_limit, skip: 0, elo: '')
      else
        ChampionGGApi::get_champion_roles(limit: champion_roles_limit, skip: 0, elo: elo)
      end

      champion_roles.each do |champion_role|
        id = champion_role['championId']
        name = ids_to_names[id]
        role = champion_role['role']

        # Add champion rankings in different positions (metrics) to the ranking lists
        supported_position_rankings = ChampionGGApi::POSITIONS.keys.map(&:to_s)
        champion_role['positions'].slice(*supported_position_rankings).to_a.each do |position_name, position|
          champion_rankings[role] ||= {}
          champion_rankings[role][position_name] ||= []
          champion_rankings[role][position_name] << { position: position, id: id }
        end
        cache_champion_matchups(name, id, elo, champion_role.delete('matchups'))

        # Cache champion role performance
        Cache.set_champion_role_performance(
          name, ChampionGGApi::ROLES[role.to_sym], elo, champion_role
        )
      end
      cache_champion_rankings(champion_rankings, elo, ids_to_names)
    end

    DataDog.event(DataDog::EVENTS[:CHAMPIONGG_CHAMPION_PERFORMANCE])
  end
end

namespace :riot do
  task daily: [:cache_champions, :cache_items, :cache_spells]
  task hourly: [:store_matches]

  def remove_tags(description)
    prepared_text = description.split("<br>")
      .reject { |effect| effect.blank? }.join("")
    strip_tags(prepared_text)
  end

  def cache_collection(key, collection)
    ids_to_names = collection.inject({}) do |acc, collection_entry|
      acc.tap do
        acc[collection_entry['id']] = collection_entry['name']
      end
    end

    Cache.set_collection(key, ids_to_names)
  end

  desc 'Store matches'
  task store_matches: :environment do
    # Use the most recently active 200 players to determine the point at which
    # no more games exist
    recent_players = SummonerPerformance.joins(:summoner)
      .order('summoner_performances.created_at DESC').limit(PLAYER_POOL_SIZE)
      .select('summoners.account_id', 'summoners.region')

    recent_game_ids = recent_players.map do |summoner|
      matches_data = RiotApi::RiotApi.get_recent_matches(
        region: summoner.region, id: summoner.account_id
      )
      if matches_data
        recent_matches = matches_data['matches']
        recent_matches.map { |match| match['gameId'] }.sort.last
      end
    end.compact.sort.reverse

    match_index = Cache.get_match_index
    end_match_index = Cache.get_end_match_index
    new_end_match_index = recent_game_ids.find do |id|
      id < end_match_index + END_MATCH_INDEX_THRESHOLD
    end || end_match_index
    batch_size = [new_end_match_index - match_index, MATCH_BATCH_SIZE].min
    new_start_match_index = match_index + batch_size

    Cache.set_match_index(new_start_match_index)
    Cache.set_end_match_index(new_end_match_index)

    batch_size.times do |i|
      # Game ids are given in order of game creation, but they
      # may not become available from the API until the games are completed
      # if an older game finishes earlier, it could appear first and cause
      # the earlier game to be skipped by this job. Delay by an hour to ensure
      # all games are ready.
      MatchWorker.perform_in(1.hour, match_index + i)
    end

    # Notify when no new match end index was found
    if new_end_match_index == end_match_index
      DataDog.event(
        DataDog::EVENTS[:RIOT_MATCHES_ERROR],
        end_index: end_match_index,
        new_start_index: new_start_match_index,
        game_ids: recent_game_ids
      )
    end

    DataDog.event(
      DataDog::EVENTS[:RIOT_MATCHES],
      matches_processed: batch_size,
      new_start_index: new_start_match_index,
      new_end_match_index: new_end_match_index,
      matches_remaining: new_end_match_index - new_start_match_index
    )
  end

  # Temporary nightly fixup task to save matchups that were somehow missed.
  # Ongoing investigation into why they were missed.
  desc 'Store matches fix'
  task store_matches_fix: :environment do
    match_index = Cache.get_fixup_match_index
    end_match_index = Cache.get_end_match_index

    retry_range = (match_index..end_match_index)
    retry_games = retry_range.to_a - Match.where(game_id: retry_range).pluck(:game_id)

    retry_games.each do |game_id|
      MatchWorker.perform_async(game_id, true)
    end

    Cache.set_fixup_match_index(end_match_index)

    DataDog.event(
      DataDog::EVENTS[:RIOT_MATCHES_FIX],
      fixup_match_index: match_index,
      end_match_index: end_match_index,
      matches_processed: batch_size
    )
  end

  desc 'Cache spells'
  task cache_spells: :environment do
    spells = RiotApi::RiotApi.get_spells.values.select do |spell|
      spell['name']
    end
    cache_collection(:spells, spells)

    spells.each do |spell_data|
      Cache.set_collection_entry(:spell, spell_data['name'], spell_data)
    end

    DataDog.event(DataDog::EVENTS[:RIOT_SPELLS])
  end

  desc 'Cache items'
  task cache_items: :environment do
    items = RiotApi::RiotApi.get_items.values.select do |item|
      item['name'] && item['description']
    end
    cache_collection(:items, items)

    items.each do |item_data|
      item_data['description'] = remove_tags(item_data[:description])
      Cache.set_collection_entry(:item, item_data['name'], item_data)
    end

    DataDog.event(DataDog::EVENTS[:RIOT_ITEMS])
  end

  desc 'Cache champions'
  task cache_champions: :environment do
    champions = RiotApi::RiotApi.get_champions.values
    cache_collection(:champions, champions)

    champions.each do |champion_data|
      id = champion_data['id']
      champion_data['blurb'] = remove_tags(champion_data['blurb'])
      champion_data['lore'] = remove_tags(champion_data['lore'])
      Cache.set_collection_entry(:champion, champion_data['name'], champion_data)
    end

    DataDog.event(DataDog::EVENTS[:RIOT_CHAMPIONS])
  end
end
