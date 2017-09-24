class SummonersController < ApplicationController
  include RiotApi
  before_action :load_summoner

  def show
    name = @summoner.name
    queue = @summoner.queue

    args = {
      name: name,
      lp: queue.lp,
      rank: queue.rank,
      winrate: queue.winrate,
      hot_streak: queue.hot_streak ? 'on' : 'not on',
      elo: queue.elo.humanize,
      queue: queue.name
    }

    render json: {
      speech: ApiResponse.get_response({ summoners: :show }, args)
    }
  end

  private

  def summoner_params
    params.require(:result).require(:parameters).permit(
      :name, :region, :champion, :queue
    )
  end

  def load_summoner
    @summoner = Summoner.new(
      name: summoner_params[:name],
      region: summoner_params[:region],
      with_queue: summoner_params[:queue]
    )

    unless @summoner.valid?
      render json: { speech: @summoner.error_message }
      return false
    end
  end
end
