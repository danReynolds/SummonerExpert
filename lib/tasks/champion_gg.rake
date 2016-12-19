require "#{Rails.root}/lib/external_api.rb"
require "#{Rails.root}/lib/riot_api.rb"
require "#{Rails.root}/lib/champion_gg_api.rb"
include RiotApi
include ChampionGGApi

namespace :champion_gg do
  desc 'Fetch all champion data from champion gg nightly'
  task fetch_nightly: :environment do
    champions = RiotApi::RiotApi.get_champions
    champions.each do |champion_name, champion_data|
      champion_data[:champion_gg] = ChampionGGApi::ChampionGGApi.get_champion(
        champion_name
      )
    end
    Rails.cache.write(:champions, champions)
  end
end
