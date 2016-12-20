class ChampionsController < ApplicationController
  include RiotApi
  before_action :load_champion

  MIN_MATCHUPS = 50
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

  def build
    name = champion_params[:champion]
    role = champion_params[:lane]
    return render json: {
      speech: (
        <<~HEREDOC
          There is no recommended way to build #{name} as #{role}. Please do not
          make your team surrender at 20.
        HEREDOC
      )
    } unless role_data = find_by_role(name, role)
    build = role_data[:items][:highestWinPercent][:items].map do |item|
      item[:name]
    end.join(', ')

    render json: {
      speech: "The highest win rate build for #{name} #{role} is #{build}"
    }
  end

  def matchup
    name = champion_params[:champion]
    role = champion_params[:lane]
    return render json: {
      speech: (
        <<~HEREDOC
          Anyone would counter #{name} #{role}, they do not belong in that
          role.
        HEREDOC
      )
    } unless role_data = find_by_role(name, role)

    counters = role_data[:matchups].select do |matchup|
      matchup[:games] > MIN_MATCHUPS
    end.sort_by do |matchup|
      matchup[:statScore]
    end.first(3).map do |counter|
      "#{counter[:key]} at #{(100 - counter[:winRate]).round(2)}% win rate"
    end.join(', ')

    render json: {
      speech: "The best counters for #{name} #{role} are #{counters}"
    }
  end

  def lane
    name = champion_params[:champion]
    role = champion_params[:lane]
    return render json: {
      speech: "#{name} is not recommended to play #{role}."
    } unless role_data = find_by_role(name, role)

    overall = role_data[:overallPosition]
    change = overall[:change] > 0 ? 'better' : 'worse'

    render json: {
      speech: (
        <<~HEREDOC
          #{name} got #{change} in the last patch and is currently ranked
          #{overall[:position]} with a #{role_data[:patchWin].last}% win rate
          and a #{role_data[:patchPlay].last}% play rate as a #{role}.
        HEREDOC
      )
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
          #{spell[:name]}. #{spell[:sanitizedDescription]}
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
          Here's a tip for playing as #{@champion[:name]}:
          #{@champion[:allytips].sample.to_s}
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

  def find_by_role(name, role)
    @champion[:champion_gg].detect do |champion_data|
      champion_data[:role] == role
    end
  end

  def remove_html_tags(speech)
    speech.gsub!(HTML_TAGS, '')
  end

  def load_champion
    @champion = RiotApi.get_champion(champion_params[:champion].strip)
  end

  def champion_params
    params.require(:result).require(:parameters).permit(
      :champion, :ability, :rank, :lane
    )
  end
end
