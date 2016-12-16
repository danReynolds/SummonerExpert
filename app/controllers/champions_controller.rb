class ChampionsController < ApplicationController
  include RiotApi

  def title
    champion_data = RiotApi.get_champion(champion_params[:champion])
    render json: {
      speech: "#{champion_data[:name]}'s title is #{champion_data[:title]}"
    }
  end

  private

  def champion_params
    params.require(:result).require(:parameters).permit(:champion)
  end
end
