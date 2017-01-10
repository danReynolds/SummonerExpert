class ChampionsController < ApplicationController
  include RiotApi
  before_action :load_champion, except: [:ranking]
  before_action :verify_role, only: [:ability_order, :build, :counters, :lane]

  MIN_MATCHUPS = 100
  STAT_PER_LEVEL = :perlevel
  RANKING_LIST_ORDER = {
    asc: :worst,
    desc: :best
  }
  COUNTERS_LIST_SIZE = 3
  HTML_TAGS = /<("[^"]*"|'[^']*'|[^'">])*>/

  def ranking
    role = champion_params[:lane]
    list_position = champion_params[:list_position].to_i
    list_size = champion_params[:list_size].to_i
    list_order = champion_params[:list_order]
    tag = champion_params[:tag]

    champions = Rails.cache.read(:champions)
    rankings = Rails.cache.read({ rankings: role })
    rankings = rankings.select { |ranking| ranking[:tags].include?(tag) } unless tag.blank?
    rankings = rankings[(list_position - 1)..-1]
    rankings.reverse! if list_order.to_sym == RANKING_LIST_ORDER[:asc]

    ranking_message = rankings.first(list_size).map do |role_data|
      champions[role_data[:key]]
    end.en.conjunction(article: false)
    list_message = list_size_message(list_size)
    list_position_message = list_position_message(list_position)
    topic_message = tag_message(tag, list_size) || "champion".pluralize(list_size)

    render json: {
      speech: (
        "The #{list_position_message}#{list_order} #{list_message}" \
        "#{topic_message} in #{role} #{"is".en.plural_verb(list_size)} " \
        "#{ranking_message}."
      )
    }
  end

  def stats
    stats = @champion[:stats]
    stat = champion_params[:stat]
    level = champion_params[:level].to_i
    stat_value = stats[stat]
    stat_name = RiotApi::STATS[stat.to_sym]
    level_message = ''

    if stat_modifier = stats["#{stat}#{STAT_PER_LEVEL}"]
      return render json: ask_for_level_response unless level.positive?

      level_message = " at level #{level}"
      stat_value += stat_modifier * (level - 1)
    end

    render json: {
      speech: (
        "#{@name} has #{stat_value.round} #{stat_name}#{level_message}."
      )
    }
  end

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
    role = champion_params[:lane]
    champion_query = champion_params[:champion1].strip
    unless other_champion = RiotApi.get_champion(champion_query)
      render json: champion_not_found_response(champion_query)
      return false
    end

    shared_roles = @champion[:champion_gg].map do |role_data|
      role_data[:role]
    end & other_champion[:champion_gg].map do |role_data|
      role_data[:role]
    end

    if shared_roles.length.zero? || !role.blank? && !shared_roles.include?(role)
      return render json: {
        speech: (
          "#{@name} and #{other_champion[:name]} do not typically play " \
          "against eachother in #{role.blank? ? 'any role' : role}."
        )
      }
    end

    if role.blank?
      if shared_roles.length == 1
        role = shared_roles.first
      else
        return render json: ask_for_role_response
      end
    end

    champion_role = find_by_role(@champion, role)
    other_champion_role = find_by_role(other_champion, role)

    matchup = champion_role[:matchups].detect do |matchup|
      matchup[:key] == other_champion[:key]
    end
    change = matchup[:winRateChange] > 0 ? 'better' : 'worse'

    return render json: {
      speech: (
        "#{@name} got #{change} against #{other_champion[:name]} in the " \
        "latest patch and has a win rate of #{matchup[:winRate]}% against " \
        "#{other_champion[:title]} in #{role}."
      )
    }
  end

  def counters
    list_size = champion_params[:list_size].to_i
    list_size = COUNTERS_LIST_SIZE unless list_size.positive?
    list_message = list_size_message(list_size)

    counters = @role_data[:matchups].select do |matchup|
      matchup[:games] > MIN_MATCHUPS
    end.sort_by do |matchup|
      matchup[:statScore]
    end.first(list_size).map do |counter|
      counter_name = Rails.cache.fetch(champions: counter[:key])[:name]
      "#{counter_name} at a #{(100 - counter[:winRate]).round(2)}% win rate"
    end.en.conjunction(article: false)
    render json: {
      speech: "The best #{list_message}counters for #{@name} #{@role} are " \
      "#{counters}."
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
      spell = @champion[:spells][RiotApi::ABILITIES[ability]]
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
    spell = @champion[:spells][RiotApi::ABILITIES[ability]]
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
    if champion_query.blank?
      render json: no_champion_specified_response
      return false
    end

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

  def no_champion_specified_response
    { speech: 'What champion are you looking for?' }
  end

  def champion_not_found_response(name)
    { speech: "I could not find a champion called '#{name}'." }
  end

  def ask_for_role_response
    { speech: 'What role are they in?' }
  end

  def ask_for_level_response
    { speech: 'What level is the champion?' }
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

  def list_size_message(size)
    size == 1 ? '' : "#{size.en.numwords} "
  end

  def tag_message(tag, size)
    return if tag.blank?
    tag.en.downcase.pluralize(size)
  end

  def list_position_message(size)
    size == 1 ? '' : "#{size.en.ordinate} "
  end

  def champion_params
    params.require(:result).require(:parameters).permit(
      :champion, :champion1, :ability, :rank, :lane, :list_size, :list_position,
      :list_order, :stat, :level, :tag
    )
  end
end
