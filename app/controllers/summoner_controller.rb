class SummonerController < ApplicationController
  def show
    uri = URI("#{RIOT_API[:summoner][:details]}/#{summoner_id(params[:id])}/ranked?season=#{RIOT_API[:season]}&api_key=#{ENV['RIOT_API_KEY']}")
    res = JSON.parse(Net::HTTP.get(uri)).with_indifferent_access
    render json: get_champion_stats(res[:champions])
  end

  private

  def get_champion_stats(champions)
    champions.reject { |champion| champion[:id].zero? }.map do |champion|
      stats = champion[:stats].slice(:totalSessionsWon, :totalSessionsPlayed)
      stats.merge(name: get_champion_from_cache(champion[:id])[:name])
    end
  end

  def get_champion_from_cache(id)
    Rails.cache.fetch(champions: id, expires_in: 24.hours) do
      fetch_champion(id).tap do |champion|
        champion.except(:id)
      end
    end
  end

  def fetch_champion(id)
    uri = URI("#{RIOT_API[:champion]}/#{id}?api_key=#{ENV['RIOT_API_KEY']}")
    JSON.parse(Net::HTTP.get(uri)).with_indifferent_access
  end

  def summoner_id(name)
    uri = URI("#{RIOT_API[:summoner][:id]}/#{name}?api_key=#{ENV['RIOT_API_KEY']}")
    response = Net::HTTP.get(uri)
    JSON.parse(response).with_indifferent_access[name][:id]
  end
end
