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
  }.freeze

  def description
    roles = @champion[:tags].join(' and ')
    render json: {
      speech: "#{@champion[:name]}, the #{@champion[:title]}, is a #{roles}."
    }
  end

  def ability
    ability = champion_params[:ability].to_sym
    if ability == :passive
      spell  @champion[:passive]
    else
      spell = @champion[:spells][ABILITIES[ability]]
    end

    render json: {
      speech: (
        <<~HEREDOC
          #{champion_params[:champion]}'s #{ability} ability is called
          #{spell[:name]}.#{spell[:sanitizedDescription]}
        HEREDOC
      )
    }
  end

  def cooldown
    ability = champion_params[:ability].to_sym
    spell = @champion[:spells][ABILITIES[ability]]
    rank = champion_params[:rank].split(' ').last.to_i

    render json: {
      speech: (
        <<~HEREDOC
          #{champion_params[:champion]}'s #{ability} ability, #{spell[:name]},
          has a cooldown of #{spell[:cooldown][rank - 1].to_i} seconds at rank
          #{rank}.
        HEREDOC
      )
    }
  end

  def title
    render json: {
      speech: "#{@champion[:name]}'s title is #{@champion[:title]}"
    }
  end

  def ally_tips
    render json: {
      speech: (
        <<~HEREDOC
          "Here's a tip for playing with #{@champion[:name]}:
          #{@champion[:allytips].sample.to_s}"
        HEREDOC
      )
    }
  end

  def enemy_tips
    render json: {
      speech: (
        <<~HEREDOC
          "Here's a tip for playing against #{@champion[:name]}:
          #{@champion[:enemytips].sample.to_s}"
        HEREDOC
      )
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
