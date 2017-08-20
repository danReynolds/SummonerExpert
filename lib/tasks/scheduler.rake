require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
include RiotApi
include ActionView::Helpers::SanitizeHelper

namespace :champion_gg do
  task all: [:cache_champion_performance, :cache_site_information]

  # Cache how a champion does in matchups against other champs in that role
  def cache_champion_matchups(name, id, elo, matchup_data)
    ids_to_names = Rails.cache.read(:champions)

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

      Rails.cache.write(
        {
          matchups: {
            name: name,
            role: ChampionGGApi::MATCHUP_ROLES[matchup_role.to_sym],
            elo: elo
          }
        },
        champion_matchups
      )
    end
  end

  # Cache the ranking lists for champion performance on metrics like kills, etc in that role
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
        Rails.cache.write(
          {
            elo: elo,
            position: position_name,
            role: ChampionGGApi::ROLES[role.to_sym]
          },
          ranked_champions
        )
      end
    end
  end

  desc 'Cache general Champion.gg site information'
  task cache_site_information: :environment do
    information = ChampionGGApi::get_site_information
    Rails.cache.write(:patch, information.first['patch'])
  end

  desc 'Cache champion role and matchup performance'
  task cache_champion_performance: :environment do
    puts 'Fetching champion data from Champion.gg'

    # Arbitrarily high enough number used for variable combinations of champions x roles
    champion_roles_limit = 10000

    ids_to_names = Rails.cache.read(:champions)

    ChampionGGApi::ELOS.values.each do |elo|
      puts "Fetching Champion data for #{elo}"
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

        # Cache how that champion does in that role overall
        Rails.cache.write({ name: name, role: ChampionGGApi::ROLES[role.to_sym], elo: elo }, champion_role)
      end
      cache_champion_rankings(champion_rankings, elo, ids_to_names)
    end

    puts 'Cached champion data from Champion.gg'
  end
end


namespace :riot do
  task all: [:cache_champions, :cache_items]

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

    Rails.cache.write(key, ids_to_names)
  end

  desc 'Cache items'
  task cache_items: :environment do
    puts 'Fetching item data from Riot'

    items = RiotApi::RiotApi.get_items.values.select do |item|
      item['name'] && item['description']
    end
    cache_collection(:items, items)

    items.each do |item_data|
      item_data['description'] = remove_tags(item_data[:description])
      Rails.cache.write({ item: item_data['name'] }, item_data)
    end

    puts 'Cached item data from Riot'
  end

  desc 'Cache champions'
  task cache_champions: :environment do
    puts 'Fetching champion data from Riot'

    champions = RiotApi::RiotApi.get_champions.values
    cache_collection(:champions, champions)

    champions.each do |champion_data|
      id = champion_data['id']
      champion_data['blurb'] = remove_tags(champion_data['blurb'])
      champion_data['lore'] = remove_tags(champion_data['lore'])
      Rails.cache.write({ champion: champion_data['name'] }, champion_data)
    end

    puts 'Cached champion data from Riot'
  end
end
