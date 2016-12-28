require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
include RiotApi
include ChampionGGApi

desc 'Fetch all champion data from champion.gg nightly'
namespace :fetch_champion_gg do
  task all: [:cache_champions, :cache_lane_rankings]

  desc 'Cache all champion data'
  task cache_champions: :environment do
    puts 'Fetching champion data from champion.gg'

    champions = RiotApi::RiotApi.get_champions
    champion_names = champions.inject({}) do |names, (key, data)|
      names.tap do |_|
        names[key] = data[:name]
      end
    end
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
          role_data = Rails.cache.read(champions: key)[:champion_gg].detect do |role_data|
            role_data[:role] == role
          end
          acc << role_data if role_data
        end
      end.sort_by do |role_data|
        role_data[:overallPosition][:position]
      end.map do |role_data|
        role_data[:key]
      end
      Rails.cache.write({ rankings: role }, rankings)

      puts "Succeeded caching rankings for #{role}."
    end
  end
end
