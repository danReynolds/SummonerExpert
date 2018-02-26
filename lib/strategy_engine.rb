class StrategyEngine
  PRIORITIES = {
    HIGHEST: 1,
    HIGH: 2,
    MEDIUM: 3,
    LOW: 4,
    LOWEST: 5
  }

  SUMMONER_COMPARISON_FACTORS = [:champion_performance, :longest_streak, :champion_matchup_performance]
  MINIMUM_PERFORMANCES = 5
  RATING_THRESHOLD = 0.1

  class << self
    def run(args)
      args[:performances] = args[:summoner].summoner_performances.joins(:match).current_season.not_remake
      args[:performances2] = args[:summoner2].summoner_performances.joins(:match).current_season.not_remake
      opposing_args = args.merge({
        performances: args[:performances2],
        performances2: args[:performances],
        summoner: args[:summoner2],
        summoner2: args[:summoner],
        champion: args[:champion2],
        champion2: args[:champion]
      })

      {
        own_rating: calculate_rating(args, calculate_factors(args)),
        opposing_rating: calculate_rating(opposing_args, calculate_factors(opposing_args))
      }
    end

    def calculate_factors(args)
      SUMMONER_COMPARISON_FACTORS.inject({}) do |acc, factor|
        acc.tap do
          acc[factor] = send(factor, args)
        end
      end
    end

    def calculate_rating(args, factors)
      weighted_factors = factors.inject({}) do |acc, (name, value)|
        acc.tap do
          priority = value[:priority] || PRIORITIES[:HIGHEST]
          acc[priority] ||= { performance: 0, total: 0 }
          priority_values = acc[priority]
          performance = value[:performance] || calculate_rating(args, value[:factors])
          priority_values[:performance] += [1, performance].min
          priority_values[:total] += 1
        end
      end
      weighted_rating = weighted_factors.inject({ rating: 0, total: 0 }) do |acc, (priority, value)|
        acc.tap do
          local_weighting = 1.0 / 2 ** priority
          acc[:rating] += value[:performance] / value[:total] * local_weighting
          acc[:total] += local_weighting
        end
      end
      weighted_rating[:rating] / weighted_rating[:total]
    end

    def champion_matchup_performance(args)
      queue = args[:summoner].queue(RankedQueue::SOLO_QUEUE)
      champion_gg_role = ChampionGGApi::MATCHUP_ROLES[args[:role].to_sym]
      matchup = Matchup.new(
        name1: args[:champion].name,
        name2: args[:champion2].name,
        elo: queue.elo,
        role1: champion_gg_role,
        role2: champion_gg_role
      )

      priority = if args[:performances].length < MINIMUM_PERFORMANCES
        PRIORITIES[:LOW]
      else
        PRIORITIES[:HIGHEST]
      end

      matchup_performances = args[:performances].where(champion_id: args[:champion].id, role: args[:role]).select { |performance| performance.opponent.champion_id == args[:champion2].id }

      own_kda = SummonerPerformance.aggregate_performance_metric(
        matchup_performances,
        RiotApi::RiotApi::POSITION_METRICS[:KDA].to_sym
      )

      opposing_kda = {
        kills: matchup.position('kills', matchup.name1),
        deaths: matchup.position('deaths', matchup.name1),
        assists: matchup.position('assists', matchup.name1)
      }

      aggregate_positions = SummonerPerformance.aggregate_performance_positions(
        matchup_performances, [:gold_earned, :total_minions_killed]
      ).inject({}) do |acc, (position, values)|
        acc.tap do
          acc[position] = (values.sum / args[:performances].length.to_f).round(2)
        end
      end

      {
        priority: priority,
        factors: {
          WIN_RATE: win_rate({
            own: SummonerPerformance.winrate(matchup_performances),
            opposing: (matchup.position('winrate', matchup.name1) * 100).round(2)
          }),
          KDA: kda({
            own: (own_kda[:kills] + own_kda[:assists]) / own_kda[:deaths].to_f,
            opposing: (opposing_kda[:kills] + opposing_kda[:assists]) / opposing_kda[:deaths].to_f
          }),
          CS: cs({
            own: aggregate_positions[:total_minions_killed],
            opposing: matchup.position('minionsKilled', matchup.name1)
          }),
          GOLD: gold({
            own: aggregate_positions[:gold_earned],
            opposing: matchup.position('goldEarned', matchup.name1)
          })
        }
      }
    end

    def longest_streak(args)
      streak = args[:performances].sort_by { |performance| performance.created_at }.reverse
      winning_streak = streak.first.victorious?
      streak_length = streak.take_while { |performance| performance.victorious? == winning_streak }.length

      if winning_streak
        if streak_length > 3
          priority = PRIORITIES[:HIGH]
          performance = 1
        elsif streak_length == 2
          priority = PRIORITIES[:MEDIUM]
          performance = 0.9
        else
          priority = PRIORITIES[:LOW]
          performance = 0.8
        end
      else
        if streak_length > 3
          priority = PRIORITIES[:HIGHEST]
          performance = 0
        elsif streak_length == 2
          priority = PRIORITIES[:MEDIUM]
          performance = 0.5
        else
          priority = PRIORITIES[:LOW]
          performance = 0.5
        end
      end

      {
        priority: priority,
        factors: {
          streak: {
            args: {
              streak_type: winning_streak ? :winning : :losing,
              streak_length: streak_length
            },
            performance: performance
          }
        }
      }
    end

    def win_rate(comparison)
      win_rate_ceiling = comparison[:opposing] + 10
      win_rate_performance = comparison[:own] / win_rate_ceiling

      {
        priority: PRIORITIES[:HIGHEST],
        args: comparison,
        performance: win_rate_performance
      }
    end

    def kda(comparison)
      kda_ceiling = comparison[:opposing] * 1.5
      kda_performance = comparison[:own] / kda_ceiling

      {
        priority: PRIORITIES[:HIGH],
        args: comparison,
        performance: kda_performance
      }
    end

    def cs(comparison)
      {
        priority: PRIORITIES[:MEDIUM],
        args: comparison,
        performance: comparison[:own] / comparison[:opposing]
      }
    end

    def gold(comparison)
      {
        priority: PRIORITIES[:MEDIUM],
        args: comparison,
        performance: comparison[:own] / comparison[:opposing]
      }
    end

    def champion_performance(args)
      champion_performances = args[:performances].where(champion_id: args[:champion].id, role: args[:role])
      champion_gg_role = ChampionGGApi::MATCHUP_ROLES[args[:role].to_sym]
      queue = args[:summoner].queue(RankedQueue::SOLO_QUEUE)
      champion_role_performance = RolePerformance.new(
        elo: queue.elo,
        role: champion_gg_role,
        name: args[:champion].name
      )

      own_kda = SummonerPerformance.aggregate_performance_metric(
        champion_performances,
        RiotApi::RiotApi::POSITION_METRICS[:KDA].to_sym
      )
      opposing_kda = champion_role_performance.kda

      aggregate_positions = SummonerPerformance.aggregate_performance_positions(
        champion_performances, [:gold_earned, :total_minions_killed]
      ).inject({}) do |acc, (position, values)|
        acc.tap do
          acc[position] = (values.sum / args[:performances].length.to_f).round(2)
        end
      end

      priority = if args[:performances].length < MINIMUM_PERFORMANCES
        PRIORITIES[:LOW]
      else
        PRIORITIES[:HIGH]
      end

      {
        priority: priority,
        factors: {
          WIN_RATE: win_rate({
            own: SummonerPerformance.winrate(champion_performances),
            opposing: (champion_role_performance.winRate * 100).round(2)
          }),
          KDA: kda({
            own: (own_kda[:kills] + own_kda[:assists]) / own_kda[:deaths].to_f,
            opposing: (opposing_kda[:kills] + opposing_kda[:assists]) / opposing_kda[:deaths].to_f
          }),
          CS: cs({
            own: aggregate_positions[:total_minions_killed],
            opposing: champion_role_performance.minionsKilled
          }),
          GOLD: gold({
            own: aggregate_positions[:gold_earned],
            opposing: champion_role_performance.goldEarned
          })
        }
      }
    end
  end
end
