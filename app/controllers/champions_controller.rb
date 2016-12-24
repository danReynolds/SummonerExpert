class ChampionsController < ApplicationController
  include RiotApi
  before_action :load_champion
  before_action :verify_role, only: [:ability_order, :build, :matchups, :lane]

  MIN_MATCHUPS = 100
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
    play_style = @champion[:tags].en.conjunction
    roles = @champion[:champion_gg].map { |variant| variant[:role] }
      .en.conjunction(article: false)

    render json: {
      speech: (
        "#{@name}, the #{@champion[:title]}, is #{play_style} and " \
        "is played as #{roles}."
      )
    }
  end

  def ability_order
    order = parse_ability_order(@role_data[:skills][:highestWinPercent][:order])
    render json: {
      speech: (
        "The highest win rate on #{@name} #{@role} has you start " \
        "#{order[:firstOrder].join(', ')} and then max " \
        "#{order[:maxOrder].join(', ')}."
      )
    }
  end

  def build
    build = @role_data[:items][:highestWinPercent][:items].map do |item|
      item[:name]
    end.en.conjunction(article: false)

    render json: {
      speech: "The highest win rate build for #{@name} #{@role} is #{build}."
    }
  end

  def matchup
    lane = champion_params[:lane]
    champion_query = champion_params[:champion1].strip
    unless other_champion = RiotApi.get_champion(champion_query)
      render json: champion_not_found_response(champion_query)
      return false
    end

    champion_role = find_by_role(@champion, lane)
    other_champion_role = find_by_role(other_champion, lane)

    if lane.blank?
      if champion_role && other_champion_role.nil?
        other_champion_role = find_by_role(other_champion, champion_role[:role])
      elsif other_champion_role && champion_role.nil?
        champion_role = find_by_role(@champion, other_champion_role[:role])
      end

      if champion_role && other_champion_role && champion_role[:role] != other_champion_role[:role]
        return render json: {
          speech: (
            "#{@name} does not play in the same role as " \
            "#{other_champion[:name]}, either one could win."
          )
        }
      elsif champion_role.nil? && other_champion_role.nil?
        return render json: ask_for_role_response
      end

      lane = champion_role[:role]
    end

    if champion_role && other_champion_role
      matchup = champion_role[:matchups].detect do |matchup|
        matchup[:key] == other_champion[:key]
      end

      change = matchup[:winRateChange] > 0 ? 'better' : 'worse'

      return render json: {
        speech: (
          "#{@name} got #{change} against #{other_champion[:name]} in the " \
          "latest patch and has a win rate of #{matchup[:winRate]}% against " \
          "#{other_champion[:title]} in #{lane}."
        )
      }
    elsif champion_role && other_champion_role.nil?
      return render json: {
        speech: (
          "#{other_champion[:name]} does not play #{champion_role[:role]}, " \
          "it is expected #{@name} will win."
        )
      }
    elsif champion_role.nil? && other_champion_role
      return render json: {
        speech: (
          "#{@name} does not play #{other_champion_role[:role]}, " \
          "it is expected #{other_champion[:name]} will win."
        )
      }
    end

    render json: {
      speech: (
        "#{@name} does not play in the same role as " \
        "#{other_champion[:name]}, either one could win."
      )
    }
  end

  def matchups
    counters = @role_data[:matchups].select do |matchup|
      matchup[:games] > MIN_MATCHUPS
    end.sort_by do |matchup|
      matchup[:statScore]
    end.first(3).map do |counter|
      counter_name = Rails.cache.fetch(champions: counter[:key])[:name]
      "#{counter_name} at a #{(100 - counter[:winRate]).round(2)}% win rate"
    end.en.conjunction(article: false)
    render json: {
      speech: "The best counters for #{@name} #{@role} are #{counters}."
    }
  end

  def lane
    overall = @role_data[:overallPosition]
    change = overall[:change] > 0 ? 'better' : 'worse'

    render json: {
      speech: (
        "#{@name} got #{change} in the last patch and is currently ranked " \
        "#{overall[:position].en.ordinate} with a " \
        "#{@role_data[:patchWin].last}% win rate and a " \
        "#{@role_data[:patchPlay].last}% play rate as #{@role}."
      )
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
      speech: (
        "#{@name}'s #{ability} ability is called " \
        "#{spell[:name]}. #{spell[:sanitizedDescription]}"
      )
    }
  end

  def cooldown
    ability = champion_params[:ability].to_sym
    spell = @champion[:spells][ABILITIES[ability]]
    rank = champion_params[:rank].split(' ').last.to_i

    render json: {
      speech: (
        "#{@name}'s #{ability} ability, #{spell[:name]}, has a cooldown of " \
        "#{spell[:cooldown][rank - 1].to_i} seconds at rank #{rank}."
      )
    }
  end

  def title
    render json: {
      speech: "#{@name}'s title is #{@champion[:title]}."
    }
  end

  def ally_tips
    render json: {
      speech: (
        "Here's a tip for playing as #{@name}: " \
        "#{@champion[:allytips].sample.to_s}"
      )
    }
  end

  def enemy_tips
    render json: {
      speech: (
        "Here's a tip for playing against #{@name}: " \
        "#{@champion[:enemytips].sample.to_s}"
      )
    }
  end

  private

  def find_by_role(champion, role)
    champion_gg = champion[:champion_gg]
    if role.blank?
      if champion_gg.length == 1
        champion_role = champion_gg.first
        return champion_role
      else
        return nil
      end
    end

    champion_gg.detect do |champion_data|
      champion_data[:role] == role
    end
  end

  def parse_ability_order(abilities)
    first_abilities = abilities.first(3)

    # Handle the case where you take two of the same abililty to begin
    if first_abilities == first_abilities.uniq
      max_order_abilities = abilities[3..-1]
    else
      first_abilities = abilities.first(4)
      max_order_abilities = abilities[4..-1]
    end

    {
      firstOrder: first_abilities,
      maxOrder: max_order_abilities.uniq.reject { |ability| ability == 'R' }
    }
  end

  def remove_html_tags(speech)
    speech.gsub!(HTML_TAGS, '')
  end

  def load_champion
    champion_query = champion_params[:champion].strip
    unless @champion = RiotApi.get_champion(champion_query)
      render json: champion_not_found_response(champion_query)
      return false
    end

    @name = @champion[:name]
  end

  def do_not_play_response(name, role)
    {
      speech: (
        <<~HEREDOC
          There is no recommended way to play #{name} as #{role}. This is not
          a good idea in the current meta.
        HEREDOC
      )
    }
  end

  def champion_not_found_response(name)
    {
      speech: "I could not find a champion called '#{name}'."
    }
  end

  def ask_for_role_response
    { speech: "What role are they in?" }
  end

  def verify_role
    @role = champion_params[:lane]
    unless @role_data = find_by_role(@champion, @role)
      if @role.blank?
        render json: ask_for_role_response
      else
        render json: do_not_play_response(@name, @role)
      end
      return false
    end

    @role = @role_data[:role] if @role.blank?
  end

  def champion_params
    params.require(:result).require(:parameters).permit(
      :champion, :champion1, :ability, :rank, :lane
    )
  end
end
