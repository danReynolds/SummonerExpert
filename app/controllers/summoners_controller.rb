class SummonersController < ApplicationController
  include RiotApi
  before_action :load_summoner

  def description
    name = @summoner.name
    id = @summoner.id
    queue = summoner_params[:queue]

    summoner_stats = RiotApi.get_summoner_stats(id: id, region: @summoner.region)
    queue_stats = summoner_stats[queue]

    return render json: {
      speech: "#{name} is not currently an active player."
    } if queue.nil? || queue_stats['inactive']

    winrate = (queue_stats['wins'].to_f / (queue_stats['wins'] + queue_stats['losses']) * 100).round(2)
    args = {
      name: name,
      lp: queue_stats['leaguePoints'],
      rank: queue_stats['rank'],
      winrate: winrate,
      hot_streak: queue_stats['hot_streak'] ? 'on' : 'not on',
      elo: queue_stats['tier'].humanize,
      queue: RiotApi::QUEUES[queue.to_sym]
    }

    render json: {
      speech: ApiResponse.get_response({ summoners: :description }, args)
    }
  end

  private

  def summoner_params
    params.require(:result).require(:parameters).permit(
      :name, :region, :champion, :queue
    )
  end

  def load_summoner
    @summoner = Summoner.new(name: summoner_params[:name], region: summoner_params[:region])

    unless @summoner.valid?
      render json: { speech: @summoner.error_message }
      return false
    end
  end
end
