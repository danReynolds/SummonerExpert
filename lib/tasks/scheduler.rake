require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
include RiotApi
include ChampionGGApi

desc 'Fetch all champion data from champion.gg nightly'
task fetch_champion_gg: :environment do
  puts 'Fetching champion data from champion.gg'

  champions = RiotApi::RiotApi.get_champions
  champions.first(1).each do |champion_name, champion_data|
    puts "Fetching data for #{champion_name}"

    champion_data[:champion_gg] = ChampionGGApi::ChampionGGApi.get_champion(
      champion_name
    )
  end
  Rails.cache.write(:champions, champions)

  puts 'Succeeded fetching champion data'
end
