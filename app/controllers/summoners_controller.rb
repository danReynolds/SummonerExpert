class SummonersController < ApplicationController
  include RiotApi
  before_action :load_summoner

  TOP_CHAMPION_SIZE = 3

  def show
    threads = []
    threads << Thread.new do
      RiotApi.get_summoner_champions(@summoner_id)
    end
    threads << Thread.new do
      RiotApi.get_summoner_stats(@summoner_id)
    end
    threads.each(&:join)
    summoner_champions = threads.first.value
    summoner_stats = threads.last.value
  end

  private

  def summoner_champions_message(summoner_champions)
    summoner_champions.sort do |champ1, champ2|
      champ2[:stats][:totalSessionsPlayed] <=> champ1[:stats][:totalSessionsPlayed]
    end.first(TOP_CHAMPION_SIZE).map do |champion|
    end
  end

  def summoner_params
    params.require(:result).require(:parameters).permit(:summoner)
  end

  def load_summoner
    @summoner_id = RiotApi.get_summoner_id(summoner_params[:summoner])
  end
end
