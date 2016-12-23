class ChampionsController < ApplicationController
  include RiotApi
  before_action :load_champion
  before_action :verify_role, only: [:ability_order, :build, :matchup, :lane]

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
        "#{overall[:position]} with a #{@role_data[:patchWin].last}% win rate " \
        "and a #{@role_data[:patchPlay].last}% play rate as #{@role}."
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
        "#{@name}'s #{ability} ability, #{spell[:name]}, " \
        "has a cooldown of #{spell[:cooldown][rank - 1].to_i} seconds at rank " \
        "#{rank}."
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

  def find_by_role(role)
    champion_gg = @champion[:champion_gg]
    if role.blank?
      if champion_gg.length == 1
        champion_role = champion_gg.first
        @role = champion_role[:role]
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
    @champion = RiotApi.get_champion(champion_params[:champion].strip)
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

  def ask_for_role_response(name)
    {
      speech: "What role is #{name} in?"
    }
  end

  def verify_role
    @role = champion_params[:lane]

    unless @role_data = find_by_role(@role)
      if @role.blank?
        render json: ask_for_role_response(@name)
      else
        render json: do_not_play_response(@name, @role)
      end
      return false
    end
  end

  def champion_params
    params.require(:result).require(:parameters).permit(
      :champion, :ability, :rank, :lane
    )
  end
end
