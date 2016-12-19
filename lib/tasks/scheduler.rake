require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
include RiotApi
include ChampionGGApi

desc 'Fetch all champion data from champion.gg nightly'
task fetch_champion_gg: :environment do
  puts 'Fetching champion data from champion.gg'

  champions = RiotApi::RiotApi.get_champions
  champions.each do |_, champion_data|
    key = champion_data[:key]
    puts "Fetching data for #{key}"
    champion_data[:champion_gg] = ChampionGGApi::ChampionGGApi.get_champion(key)
    Rails.cache.write({ champions: key }, champion_data)
    puts "Wrote data for #{key}"
  end
  puts 'Succeeded fetching champion data'
end
