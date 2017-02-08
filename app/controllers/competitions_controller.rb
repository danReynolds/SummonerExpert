class CompetitionsController < ApplicationController
  require 'capybara'
  require 'capybara/poltergeist'

  def standings
    standings = CompetitionApi::CompetitionApi.get_standings(
      competition_params.to_hash
    )
    binding.pry
  end

  private

  def competition_params
    params.require(:result).require(:parameters).permit(:competition, :region)
  end
end
