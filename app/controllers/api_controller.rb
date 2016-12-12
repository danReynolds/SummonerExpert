class ApiController < ApplicationController
  def index
    render json: { name: summoner_id(params[:name]) }
  end

  private

  def summoner_id(name)
    uri = URI("#{RIOT_API[:summoner_id]}/#{name}?api_key=#{ENV['RIOT_API_KEY']}")
    response = Net::HTTP.get(uri)
    JSON.parse(response).with_indifferent_access[name][:id]
  end
end
