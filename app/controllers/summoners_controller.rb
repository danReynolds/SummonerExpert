class SummonersController < ApplicationController
  include RiotApi
  include Utils
  before_action :load_summoner, :load_namespace
  before_action only: [:champion_performance_ranking] { process_performance_request(with_sorting: true) }
  before_action only: [:champion_performance_summary, :champion_performance_position] do
    process_performance_request(with_role: true, with_champion: true)
  end
  before_action only: [:champion_build, :champion_matchup_ranking] do
    process_performance_request(with_role: true, with_champion: true, with_sorting: true)
  end

  def performance_summary
    name = @summoner.name
    queue = @summoner.queue(summoner_params[:queue])

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
      speech: ApiResponse.get_response(dig_set(*@namespace), args)
    }
  end

  def champion_build
    champion = Champion.new(name: summoner_params[:champion])
    args = @processed_request[:args].merge({ champion: champion.name })

    performances_by_build = @processed_request[:performances].select(&:full_build?).group_by do |performance|
      performance.items.map(&:name).sort
    end

    if performances_by_build.empty?
      namespace = dig_set(
        :errors, *@namespace, *dig_list(@processed_request[:namespace]), :no_complete_builds
      )
      return render json: { speech: ApiResponse.get_response(namespace, args) }
    end

    build_filter = Filterable.new({
      collection: performances_by_build,
      sort_method: performance_ranking_sort(@processed_request[:sort_type]),
      reverse: true,
      list_size: 1,
      list_order: summoner_params[:list_order]
    })
    _, performances = build_filter.filter.first
    filter_types = build_filter.filter_types

    most_common_ordering = performances.group_by { |performance| performance.items.map(&:name) }
      .sort_by { |performance_group| performance_group.last.length * -1 }.first.first

    args.merge!(ApiResponse.filter_args(build_filter))
    args[:build] = most_common_ordering.en.conjunction(article: false)

    namespace = dig_set(*@namespace, *@processed_request[:namespace], *filter_types.values)
    render json: { speech: ApiResponse.get_response(namespace, args) }
  end

  def champion_matchup_ranking
    args = @processed_request[:args]
    matchup_rankings = @processed_request[:performances].map(&:opponent)
      .compact.group_by(&:champion_id).to_a

    if matchup_rankings.empty?
      namespace = dig_set(
        :errors, *@namespace, *dig_list(@processed_request[:namespace]), :no_opponents
      )
      return render json: { speech: ApiResponse.get_response(namespace, args) }
    end

    matchup_filter = Filterable.new({
      collection: matchup_rankings,
      sort_method: performance_ranking_sort(@processed_request[:sort_type]),
      reverse: true
    }.merge(summoner_params.slice(:list_order, :list_size, :list_position)))

    filtered_rankings = matchup_filter.filter
    filter_types = matchup_filter.filter_types
    args.merge!(ApiResponse.filter_args(matchup_filter))
    ids_to_names = Cache.get_collection(:champions)
    champions = filtered_rankings.map { |performance_data| ids_to_names[performance_data.first] }

    args.merge!({
      champions: champions.en.conjunction(article: false),
      real_size_champion_conjugation: 'champion'.en.pluralize(matchup_filter.real_size)
    })

    namespace = dig_set(*@namespace, *@processed_request[:namespace], *filter_types.values)
    render json: { speech: ApiResponse.get_response(namespace, args) }
  end

  def champion_performance_ranking
    args = @processed_request[:args]
    role_type = summoner_params[:role].present? ? :role_specified : :no_role_specified

    performance_filter = Filterable.new({
      collection: @processed_request[:performances].group_by(&:champion_id).to_a,
      sort_method: performance_ranking_sort(@processed_request[:sort_type]),
      reverse: true
    }.merge(summoner_params.slice(:list_order, :list_size, :list_position)))

    filtered_rankings = performance_filter.filter
    filter_types = performance_filter.filter_types
    filter_args = ApiResponse.filter_args(performance_filter)
    ids_to_names = Cache.get_collection(:champions)
    champions = filtered_rankings.map { |performance_data| ids_to_names[performance_data.first] }

    args.merge!({
      champions: champions.en.conjunction(article: false),
      real_size_champion_conjugation: 'champion'.en.pluralize(performance_filter.real_size)
    }).merge!(filter_args)

    namespace = dig_set(*@namespace, *@processed_request[:namespace], *filter_types.values, role_type)
    render json: { speech: ApiResponse.get_response(namespace, args) }
  end

  def champion_performance_position
    position = summoner_params[:position_details].to_sym
    args = @processed_request[:args]
    performances = @processed_request[:performances]
    aggregate_performance = SummonerPerformance::aggregate_performance(performances, [position])

    args[:position_name] = RiotApi::POSITION_DETAILS[position]
    args[:position_value] = (aggregate_performance[position].sum / performances.count).round(2)

    render json: {
      speech: ApiResponse.get_response(dig_set(*@namespace, @processed_request[:namespace]), args)
    }
  end

  def champion_performance_summary
    positions = [:kills, :deaths, :assists]
    args = @processed_request[:args]
    performances = @processed_request[:performances]
    aggregate_performance = SummonerPerformance::aggregate_performance(performances, positions)

    positions.each do |position|
      args[position] = (aggregate_performance[position].sum / performances.count).round(2)
    end
    args[:winrate] = SummonerPerformance::winrate(performances)

    render json: {
      speech: ApiResponse.get_response(dig_set(*@namespace, @processed_request[:namespace]), args)
    }
  end

  private

  def summoner_params
    params.require(:result).require(:parameters).permit(
      :name, :region, :champion, :queue, :role, :position_details, :metric,
      :list_order, :list_size, :list_position, :recency
    )
  end

  def does_not_play_response(args, role, recency, champion = nil)
    role_type = if role.present?
      args[:role] = ChampionGGApi::ROLES[role.to_sym].humanize
      :role_specified
    else
      :no_role_specified
    end
    recency_type = recency.present? ? :recency : :no_recency
    champion_type = champion.present? ? :champion : :no_champion

    render json: {
      speech: ApiResponse.get_response(
        dig_set(:errors, :summoners, :does_not_play, champion_type, role_type, recency_type),
        args
      )
    }
    false
  end

  def multiple_roles_response(args, collection, recency)
    args[:roles] = collection.sort.map do |role|
      ChampionGGApi::ROLES[role.to_sym].humanize
    end.en.conjunction(article: false)
    recency_type = recency.present? ? :recency : :no_recency

    render json: {
      speech: ApiResponse.get_response(
        dig_set(:errors, :summoners, :multiple_roles, recency_type),
        args
      )
    }
    false
  end

  def performance_ranking_sort(sort_type)
    case sort_type
    when :count
      ->(performance_data) do
        group_by_index, performances = performance_data
        [performances.count, group_by_index]
      end
    when :KDA
      ->(performance_data) do
        group_by_index, performances = performance_data
        [performances.map(&:kda).sum / performances.count, group_by_index]
      end
    when :winrate
      ->(performance_data) do
        group_by_index, performances = performance_data
        [performances.select(&:victorious?).count / performances.count.to_f, group_by_index]
      end
    else
      ->(performance_data) do
        group_by_index, performances = performance_data
        sort_method = performances.map { |performance| performance.send(sort_type) }
         .sum / performances.count.to_f
       [sort_method, group_by_index]
      end
    end
  end

  def process_performance_request(options = {})
    role = summoner_params[:role].to_sym
    recency = summoner_params[:recency].to_sym

    args = { name: @summoner.name }
    namespace = {}
    filter = {}
    filter[:role] = role if role.present?

    if options[:with_champion]
      champion = Champion.new(name: summoner_params[:champion])
      args[:champion] = champion.name
      filter[:champion_id] = champion.id
    end

    if options[:with_sorting]
      metric = summoner_params[:metric].to_sym
      position_details = summoner_params[:position_details].to_sym

      sort_type = if metric.present?
        args[:sort_type] = RiotApi::POSITION_METRICS[metric]
        metric
      elsif position_details.present?
        args[:sort_type] = RiotApi::POSITION_DETAILS[position_details]
        position_details
      else
        args[:sort_type] = RiotApi::POSITION_METRICS[:winrate]
        :winrate
      end
    end

    summoner_performances = if recency.present?
      namespace = dig_set(:recency)
      @summoner.summoner_performances.where(filter).where('created_at > ?', 1.month.ago)
    else
      namespace = dig_set(:no_recency)
      @summoner.summoner_performances.where(filter)
    end

    total_performances = summoner_performances.length
    return does_not_play_response(args, role, recency, champion) if total_performances.zero?
    args[:total_performances] = "#{total_performances.to_i.en.numwords} #{'time'.pluralize(total_performances)}"

    if options[:with_role]
      unless role.present?
        roles = summoner_performances.map(&:role).uniq
        if roles.length == 1
          role = roles.first
        else
          return multiple_roles_response(args, roles, recency)
        end
      end
    end
    args[:role] = ChampionGGApi::ROLES[role.to_sym].humanize if role.present?

    @processed_request = {
      args: args,
      sort_type: sort_type,
      performances: summoner_performances,
      namespace: namespace
    }
  end

  def load_namespace
    @namespace = [controller_name.to_sym, action_name.to_sym]
  end

  def load_summoner
    @summoner = Summoner.find_by(
      name: summoner_params[:name],
      region: summoner_params[:region]
    )

    unless @summoner.try(:valid?)
      recency_type = summoner_params[:recency].present? ? :recency : :no_recency
      speech = @summoner ? @summoner.error_message : ApiResponse.get_response(
        dig_set(:errors, :summoners, :not_active, recency_type),
        { name: summoner_params[:name] }
      )
      render json: { speech: speech }
      return false
    end
  end
end
