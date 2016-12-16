class ChampionsController < ApplicationController
  include RiotApi
  before_action :load_champion

  HTML_TAGS = /<("[^"]*"|'[^']*'|[^'">])*>/
  ABILITIES = {
    first: 0,
    q: 0,
    second: 1,
    w: 1,
    third: 2,
    e: 2,
    r: 3,
    ultimate: 3,
    fourth: 3
  }

  def description
    roles = @champion[:tags].join(' and ')
    blurb = remove_html_tags(@champion[:blurb])
    render json: {
      speech: "#{@champion[:name]} is a #{roles}. #{blurb}"
    }
  end

  def ability
    ability = champion_params[:ability].to_sym
    if ability == :passive
      spell = @champion[:passive]
    else
      spell = @champion[:spells][ABILITIES[ability]]
    end

    render json: {
      speech: "
        #{champion_params[:champion]}'s #{ability} ability is called #{spell[:name]}.
        #{spell[:sanitizedDescription]}
      "
    }
  end

  def cooldown
    ability = champion_params[:ability].to_sym
    spell = @champion[:spells][ABILITIES[ability]]
    rank = champion_params[:rank].split(' ').last.to_i

    render json: {
      speech: "
        #{champion_params[:champion]}'s #{ability} ability cooldown is
        #{spell[:cooldown][rank].to_i} seconds at rank #{rank}.
      "
    }
  end

  def title
    render json: {
      speech: "#{@champion[:name]}'s title is #{@champion[:title]}"
    }
  end

  def ally_tips
    render json: {
      speech: @champion[:allytips].sample.to_s
    }
  end

  def enemy_tips
    render json: {
      speech: @champion[:enemytips].sample.to_s
    }
  end

  private

  def remove_html_tags(speech)
    speech.gsub!(HTML_TAGS, '')
  end

  def load_champion
    @champion = RiotApi.get_champion(champion_params[:champion])
  end

  def champion_params
    params.require(:result).require(:parameters).permit(
      :champion, :ability, :rank
    )
  end
end
