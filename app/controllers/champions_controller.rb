class ChampionsController < ApplicationController
  include RiotApi
  include Utils
  before_action :load_champion, except: [:ranking, :matchup, :matchup_ranking]
  before_action :load_matchup, only: :matchup
  before_action :load_role_performance, only: [:role_performance_summary, :role_performance, :build, :ability_order]
  before_action :load_matchup_ranking, only: :matchup_ranking

  def ranking
    ranking_params = champion_params.slice(:position, :elo, :role).values
    rankings = Cache.get_champion_rankings(*ranking_params)
    rankings_filter = Filterable.new({
      collection: rankings
    }.merge(champion_params.slice(:list_position, :list_size, :list_order)))

    filtered_rankings = rankings_filter.filter
    list_position = rankings_filter.list_position
    real_size = rankings_filter.real_size
    filtered_size = rankings_filter.filtered_size
    filter_types = rankings_filter.filter_types

    args = {
      position: ChampionGGApi::POSITIONS[champion_params[:position].to_sym],
      role: champion_params[:role].humanize,
      elo: champion_params[:elo].humanize,
      names: filtered_rankings.en.conjunction(article: false),
      real_size: real_size.en.numwords,
      requested_size: rankings_filter.requested_size.en.numwords,
      filtered_size: filtered_size.en.numwords,
      list_position: list_position.en.ordinate, # starting position requested
      filtered_position_offset: (list_position + filtered_size - 1).en.ordinate, # end position given position and filtered size
      list_order: rankings_filter.list_order,
      real_size_champion_conjugation: 'champion'.en.pluralize(real_size)
    }

    namespace = dig_set([
      :ranking,
      filter_types[:size_type],
      filter_types[:position_type],
      filter_types[:fulfillment_type]
    ])

    render json: {
      speech: ApiResponse.get_response({ champions: namespace }, args)
    }
  end

  def stats
    stat_key = champion_params[:stat].to_sym
    level = champion_params[:level].to_i

    return render json: {
      speech: ApiResponse.get_response({ errors: { stats: :level }})
    } if level < 0 || level > 18

    args = {
      name: @champion.name,
      level: level,
      stat_name: RiotApi::STATS[stat_key],
      stat: @champion.stat(stat_key, level).round(2)
    }

    render json: {
      speech: ApiResponse.get_response({ champions: :stats }, args)
    }
  end

  def ability_order
    order = @role_performance.ability_order(champion_params[:metric])
    args = {
      name: @champion.name,
      metric: ChampionGGApi::METRICS[champion_params[:metric].to_sym],
      start_order: order[:start_order].join(', '),
      max_order: order[:max_order].join(', '),
      elo: @role_performance.elo.humanize,
      role: @role_performance.role.humanize
    }

    render json: {
      speech: ApiResponse.get_response({ champions: :ability_order }, args)
    }
  end

  def build
    metric = champion_params[:metric]
    ids_to_names = Cache.get_collection(:items)
    item_names = @role_performance.item_ids(metric).map do |id|
      ids_to_names[id]
    end.en.conjunction(article: false)

    args = {
      elo: @role_performance.elo.humanize,
      role: @role_performance.role.humanize,
      item_names: item_names,
      name: @role_performance.name,
      metric: ChampionGGApi::METRICS[metric.to_sym]
    }

    render json: {
      speech: ApiResponse.get_response({ champions: :build }, args)
    }
  end

  def matchup
    position = champion_params[:matchup_position]
    matchup_position = ChampionGGApi::MATCHUP_POSITIONS[position.to_sym]
    champ1_result = @matchup.position(position, @matchup.name1)
    champ2_result = @matchup.position(position, @matchup.name2)
    role1 = ChampionGGApi::MATCHUP_ROLES[@matchup.position('role', @matchup.name1).to_sym]
    role2 = ChampionGGApi::MATCHUP_ROLES[@matchup.position('role', @matchup.name2).to_sym]
    role_type = @matchup.role_type

    response_query = {}
    if matchup_position == ChampionGGApi::MATCHUP_POSITIONS[:winrate]
      champ1_result *= 100
      champ2_result *= 100
      response_query[role_type] = :winrate
    else
      response_query[role_type] = :general
    end

    args = {
      position: matchup_position,
      champ1_result: champ1_result.round(2),
      champ2_result: champ2_result.round(2),
      elo: @matchup.elo.humanize,
      role1: role1.humanize,
      role2: role2.humanize,
      name1: @matchup.name1,
      name2: @matchup.name2,
      match_result: champ1_result > champ2_result ? 'higher' : 'lower'
    }

    render json: {
      speech: ApiResponse.get_response({ champions: { matchup: response_query } }, args)
    }
  end

  def matchup_ranking
    matchup_position = champion_params[:matchup_position]
    matchup_role = @matchup_ranking.matchup_role
    name = @matchup_ranking.name

    rankings_filter = Filterable.new({
      collection: @matchup_ranking.matchups,
      # the default sort order is best = lowest
      sort_value: ->(name, matchup) { matchup[name][matchup_position] * -1 }
    }.merge(champion_params.slice(:list_position, :list_size, :list_order)))

    filtered_rankings = rankings_filter.filter.map { |ranking| ranking.first.dup }
    filter_types = rankings_filter.filter_types
    list_position = rankings_filter.list_position
    real_size = rankings_filter.real_size
    requested_size = rankings_filter.requested_size
    filtered_size = rankings_filter.filtered_size

    args = {
      elo: @matchup_ranking.elo.humanize,
      position: ChampionGGApi::MATCHUP_POSITIONS[matchup_position.to_sym],
      unnamed_role: @matchup_ranking.unnamed_role.humanize,
      named_role: @matchup_ranking.named_role.humanize,
      name: @matchup_ranking.name,
      real_size: real_size.en.numwords,
      requested_size: requested_size.en.numwords,
      filtered_size: filtered_size.en.numwords,
      names: filtered_rankings.en.conjunction(article: false),
      list_position: list_position.en.ordinate,
      filtered_position_offset: (list_position + filtered_size - 1).en.ordinate,
      list_order: rankings_filter.list_order,
      real_size_champion_conjugation: 'champion'.en.pluralize(real_size)
    }
    namespace = dig_set([
      :matchup_ranking,
      filter_types[:size_type],
      filter_types[:position_type],
      filter_types[:fulfillment_type],
      @matchup_ranking.role_type
    ])

    render json: {
      speech: ApiResponse.get_response({ champions: namespace }, args)
    }
  end

  def role_performance
    position = champion_params[:position_details].to_sym
    return render json: {
      speech: ApiResponse.get_response(
        { errors: { role_performance: :no_position_details } },
        {
          role: @role_performance.role.humanize,
          name: @role_performance.name,
        }
      )
    } if position.blank?

    position_performance = @role_performance.send(position)
    percentage_positions = ChampionGGApi::POSITION_DETAILS.slice(
      :winRate, :playRate, :percentRolePlayed, :banRate,
    ).keys

    if percentage_positions.include?(position)
      position_performance *= 100
      position_type = :percentage
    else
      position_type = :absolute
    end

    args = {
      elo: @role_performance.elo.humanize,
      role: @role_performance.role.humanize,
      name: @role_performance.name,
      position: position_performance.round(2),
      position_name: ChampionGGApi::POSITION_DETAILS[position]
    }

    render json: {
      speech: ApiResponse.get_response({ champions: { role_performance: position_type } }, args)
    }
  end

  # Provides a summary of a champion's performance in a lane
  # including factors such as KDA, overall performance ranking, percentage played in that
  # lane and more.
  def role_performance_summary
    overall_performance = @role_performance.position(:overallPerformanceScore)
    previous_overall_performance = @role_performance.position(:previousOverallPerformanceScore)
    position = overall_performance[:position]

    position_change = if previous_overall_performance[:position].nil?
      'new'
    elsif previous_overall_performance[:position] > position
      'doing better'
    elsif previous_overall_performance[:position] < position
      'doing worse'
    else
      'doing the same'
    end

    args = {
      elo: @role_performance.elo.humanize,
      role: @role_performance.role.humanize,
      name: @role_performance.name,
      win_rate: "#{(@role_performance.winRate * 100).round(2)}%",
      ban_rate: "#{(@role_performance.banRate * 100).round(2)}%",
      kda: @role_performance.kda.values.map { |val| val.round(2) }.join('/'),
      position: position.en.ordinal,
      total_positions: overall_performance[:total_positions],
      position_change: position_change
    }

    render json: {
      speech: ApiResponse.get_response({ champions: :role_performance_summary }, args)
    }
  end

  def ability
    ability_position = champion_params[:ability_position]
    ability = @champion.ability(ability_position.to_sym)
    args = {
      position: ability_position,
      description: ability[:sanitizedDescription],
      champion_name: @champion.name,
      ability_name: ability[:name]
    }

    render json: {
      speech: ApiResponse.get_response({ champions: :ability }, args)
    }
  end

  def cooldown
    ability_position = champion_params[:ability_position].to_sym
    rank = champion_params[:rank].to_i
    ability = @champion.ability(ability_position)

    return render json: {
      speech: ApiResponse.get_response({ errors: { cooldown: :rank }})
    } if rank < 1 || rank > 5

    args = {
      name: @champion.name,
      rank: rank,
      ability_position: ability_position,
      ability_name: ability[:name],
      ability_cooldown: ability[:cooldown][rank].to_i
    }

    render json: {
      speech: ApiResponse.get_response({ champions: :cooldown }, args)
    }
  end

  def lore
    args = { name: @champion.name, lore: @champion.blurb }

    render json: {
      speech: ApiResponse.get_response({ champions: :lore }, args)
    }
  end

  def title
    args = { title: @champion.title, name: @champion.name }
    render json: {
      speech: ApiResponse.get_response({ champions: :title }, args)
    }
  end

  def ally_tips
    tip = remove_html_tags(@champion.allytips.sample.to_s)
    args = { name: @champion.name, tip: tip }

    render json: {
      speech: ApiResponse.get_response({ champions: :allytips }, args)
    }
  end

  def enemy_tips
    tip = remove_html_tags(@champion.enemytips.sample.to_s)
    args = { name: @champion.name, tip: tip }

    render json: {
      speech: ApiResponse.get_response({ champions: :enemytips }, args)
    }
  end

  private

  HTML_TAGS = /<("[^"]*"|'[^']*'|[^'">])*>/
  def remove_html_tags(speech)
    speech.gsub(HTML_TAGS, '')
  end

  # Used to keep mic open when a response is needed
  def expect_user_response
    {
      data: {
        google: { expect_user_response: true }
      }
    }
  end

  def load_reply(collection)
    return true if collection.valid?

    reply = { speech: collection.error_message }
    reply.merge!(expect_user_response) if collection.try(:expect_user_response)
    render json: reply
    return false
  end

  def load_matchup
    @matchup = Matchup.new(
      name1: champion_params[:name1],
      name2: champion_params[:name2],
      elo: champion_params[:elo],
      role1: champion_params[:role1],
      role2: champion_params[:role2]
    )
    load_reply(@matchup)
  end

  def load_matchup_ranking
    @matchup_ranking = MatchupRanking.new(
      name: champion_params[:name],
      elo: champion_params[:elo],
      role1: champion_params[:role1],
      role2: champion_params[:role2]
    )
    load_reply(@matchup_ranking)
  end

  def load_champion
    @champion = Champion.new(name: champion_params[:name])
    load_reply(@champion)
  end

  def load_role_performance
    @role_performance = RolePerformance.new(
      elo: champion_params[:elo],
      role: champion_params[:role],
      name: @champion.name
    )
    load_reply(@role_performance)
  end

  def champion_params
    params.require(:result).require(:parameters).permit(
      :name, :champion1, :ability_position, :rank, :role, :list_size, :list_position,
      :list_order, :stat, :level, :tag, :elo, :metric, :position, :name1, :name2,
      :matchup_position, :role1, :role2, :position_details
    )
  end
end
