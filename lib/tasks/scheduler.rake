require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
require "#{Rails.root}/lib/league_thekev_api.rb"
include RiotApi
include ChampionGGApi
include LeagueThekevApi
include ActionView::Helpers::SanitizeHelper

desc 'Fetch all champion data from champion.gg nightly'
namespace :fetch_champion_gg do
  task all: [:cache_champions, :cache_lane_rankings, :cache_items]

  def format_description(description)
    prepared_text = description.split("<br>")
      .reject { |effect| effect.blank? }.join("\n")
    strip_tags(prepared_text)
  end

  def parse_names(obj)
    obj.inject({}) do |names, (key, data)|
      names.tap { names[key] = data[:name] if data[:name] }
    end
  end

  desc 'Cache all items data'
  task cache_items: :environment do
    puts 'Fetching item data from champion.gg'

    items = RiotApi::RiotApi.get_items
    item_names = parse_names(items)
    Rails.cache.write(:items, item_names)
    failures = []
    items.each do |_, item|
      if item[:description]
        begin
          efficiency = LeagueThekevApi::LeagueThekevApi.get_item(item[:id])
          item[:description] = format_description(item[:description])
          item[:cost_analysis] = efficiency.with_indifferent_access[:data]
          .first[:attributes]
        rescue Exception => e
          failures << {
            id: item[:id],
            error: e
          }
        end
        Rails.cache.write({ items: item[:name] }, item)
      end
    end
    binding.pry
    puts 'Fetched item data from champion.gg'
  end

  desc 'Cache all champion data'
  task cache_champions: :environment do
    puts 'Fetching champion data from champion.gg'

    champions = RiotApi::RiotApi.get_champions
    champion_names = parse_names(champions)
    Rails.cache.write(:champions, champion_names)

    champions.each do |_, champion_data|
      key = champion_data[:key]
      puts "Fetching data for #{key}"
      champion_data[:champion_gg] = ChampionGGApi::ChampionGGApi.get_champion(key)
      Rails.cache.write({ champions: key }, champion_data)
      puts "Wrote data for #{key}"
    end

    puts 'Succeeded fetching champion data'
  end

  desc 'Cache champion rankings in all lanes'
  task cache_lane_rankings: :environment do
    champions = Rails.cache.read(:champions)

    RiotApi::RiotApi::ROLES.each do |role|
      puts "Caching rankings for #{role}."

      rankings = champions.keys.inject([]) do |acc, key|
        acc.tap do |_|
          champion = Rails.cache.read(champions: key)
          role_data = champion[:champion_gg].detect do |role_data|
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
