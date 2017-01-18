class SummonersController < ApplicationController
  include RiotApi
  require 'thread/future'
  before_action :load_summoner
  before_action :load_champion, only: :champion

  BEST_CHAMPION_SIZE = 3

  def show
    name = @summoner.name
    id = @summoner.id
    region = @region.region

    summoner_stats = Thread.future do
      RiotApi.get_summoner_stats(id: id, region: region)
    end
    summoner_champions = Thread.future do
      RiotApi.get_summoner_champions(id: id, region: region)
    end

    stats = ~summoner_stats
    champions = ~summoner_champions
    return render json: no_games_response unless stats

    render json: {
      speech: (
        "#{name} #{summoner_stats_message(stats)}. Playing " \
        "#{name}'s most common champions, the summoner has " \
        "#{summoner_champions_message(champions)}."
      )
    }
  end

  def champion
    id = @summoner.id
    region = @region.region

    summoner_champion_data = RiotApi.get_summoner_champions(
    id: id,
    region: region
    ).detect do |champion|
      champion[:id] == @champion.id
    end
    return render json: does_not_play_response unless summoner_champion_data

    summoner_champion = SummonerChampion.new(summoner_champion_data)
    towers = summoner_champion.towers
    total_games = summoner_champion.total_sessions

    render json: {
      speech: (
        "#{@summoner.name} has a #{summoner_champion.kda} KDA and " \
        "#{summoner_champion.win_rate}% win rate on #{@champion.name} " \
        "overall in #{total_games} #{'game'.en.pluralize(total_games)}. The " \
        "summoner takes an average of #{towers} " \
        "#{'tower'.en.pluralize(towers)}, #{summoner_champion.cs} cs and " \
        "#{summoner_champion.gold} gold per game."
      )
    }
  end

  private

  def does_not_play_response
    { speech: "#{@summoner.name} does not play #{@champion.name}." }
  end

  def no_games_response
    { speech: "#{@summoner.name} has not played any games this season." }
  end

  def summoner_stats_message(summoner_stats)
    hot_streak = false
    message = summoner_stats.map do |stats|
      hot_streak ||= stats[:isHotStreak]
      "is ranked #{stats[:tier]} #{stats[:division]} with " \
      "#{stats[:leaguePoints]}LP in #{stats[:queue]}"
    end.en.conjunction(article: false)

    message.tap do
      message.prepend('is on a hot streak. The player ') if hot_streak
    end
  end

  def summoner_champions_message(summoner_champions)
    champions = Rails.cache.read(:champions)

    summoner_champions.sort do |champ1, champ2|
      champ2[:stats][:totalSessionsPlayed] <=> champ1[:stats][:totalSessionsPlayed]
    end.first(BEST_CHAMPION_SIZE).map do |champion|
      name = champions.values.detect do |data|
        data[:id] == champion[:id]
      end[:name]

      stats = champion[:stats]
      winrate = stats[:totalSessionsWon] / stats[:totalSessionsPlayed].to_f * 100
      "#{winrate.round(2)}% win rate on #{name} in " \
      "#{stats[:totalSessionsPlayed]} games"
    end.en.conjunction
  end

  def summoner_params
    params.require(:result).require(:parameters).permit(
      :summoner, :region, :champion
    )
  end

  def load_champion
    @champion = Champion.new(name: summoner_params[:champion])
  end

  def load_summoner
    @region = Region.new(region: summoner_params[:region])
    unless @region.valid?
      render json: { speech: @region.error_message }
      return false
    end

    @summoner = Summoner.new(name: summoner_params[:summoner])
    @summoner.id = RiotApi.get_summoner_id(
      name: @summoner.name,
      region: @region.region
    )

    unless @summoner.valid?
      render json: { speech: @summoner.error_message }
      return false
    end
  end
end
