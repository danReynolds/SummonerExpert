require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
require "#{Rails.root}/lib/league_thekev_api.rb"
include RiotApi
include ChampionGGApi
include ActionView::Helpers::SanitizeHelper

desc 'Fetch all champion data from champion.gg nightly'
namespace :fetch_champion_gg do
  THREAD_POOL_SIZE = 20

  task all: [:cache_champions, :cache_lane_rankings, :cache_items]

  def format_description(description)
    prepared_text = description.split("<br>")
      .reject { |effect| effect.blank? }.join("\n")
    strip_tags(prepared_text)
  end

  def parse_objects(obj)
    obj.inject({}) do |objs, (key, data)|
      objs.tap do
        objs[key] = data.slice(:name, :id) if data[:name]
      end
    end
  end

  desc 'Cache all items data'
  task cache_items: :environment do
    puts 'Fetching item data from Riot and LeagueTheKev'

    items = RiotApi::RiotApi.get_items
    Rails.cache.write(:items, parse_objects(items))

    items.each do |_, item|
      if item[:description]
        efficiency = LeagueThekevApi::LeagueThekevApi.get_item(id: item[:id])
        item[:description] = format_description(item[:description])
        item[:cost_analysis] = efficiency
        Rails.cache.write({ items: item[:name] }, item)
        puts "Cached data for #{item[:name]}"
      end
    end

    puts 'Fetched item data from Riot and LeagueTheKev'
  end

  desc 'Cache all champion data'
  task cache_champions: :environment do
    puts 'Fetching champion data from champion.gg'

    champions = RiotApi::RiotApi.get_champions
    Rails.cache.write(:champions, parse_objects(champions))

    champions.each do |_, champion_data|
      key = champion_data[:key]
      champion_data[:roles] = ChampionGGApi::ChampionGGApi.get_champion(key: key)
      Rails.cache.write({ champions: champion_data[:name] }, champion_data)
      puts "Wrote data for #{key}"
    end

    puts 'Succeeded fetching champion data'
  end

  desc 'Cache champion rankings in all lanes'
  task cache_lane_rankings: :environment do
    champions = Rails.cache.read(:champions)

    RiotApi::RiotApi::ROLES.each do |role|
      puts "Caching rankings for #{role}."

      rankings = champions.values.inject([]) do |acc, data|
        acc.tap do |_|
          champion = Rails.cache.read(champions: data[:name])
          role_data = champion[:roles].detect do |role_data|
            role_data[:role] == role
          end
          acc << role_data.merge!(champion.slice(:tags)) if role_data
        end
      end.sort_by do |role_data|
        role_data[:overallPosition][:position]
      end.map do |role_data|
        role_data.slice(:key, :tags)
      end
      Rails.cache.write({ rankings: role }, rankings)

      puts "Succeeded caching rankings for #{role}."
    end
  end
end
