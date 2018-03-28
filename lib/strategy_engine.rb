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
  INEXPERIENCE_MULTIPLIER = 0.1
  OFF_META_CHAMPION_FACTOR = 0.4
  OFF_META_MATCHUP_FACTOR = 0.5
  STANDARD_WIN_RATE = 0.5
  STANDARD_KDA = 2

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
        own_performance: calculate_rating(calculate_factors(args)),
        opposing_performance: calculate_rating(calculate_factors(opposing_args))
      }
    end

    def calculate_factors(args)
      SUMMONER_COMPARISON_FACTORS.inject({}) do |acc, factor|
        acc.tap do
          acc[factor] = send(factor, args)
        end
      end
    end

    def calculate_rating(priorities = [], factors)
      reasons = []
      weighted_factors = factors.inject({}) do |acc, (name, value)|
        acc.tap do
          priority = value[:priority] || PRIORITIES[:HIGHEST]
          factor_priorities = priorities + [priority]
          acc[priority] ||= { performance: 0, total: 0 }
          priority_values = acc[priority]
          performance = if value[:performance]
            reasons << { priorities: factor_priorities, name: name, args: value[:args] || {} }
            value[:performance]
          else
            performance_rating = calculate_rating(factor_priorities, value[:factors])
            reasons += performance_rating[:reasons]
            performance_rating[:rating]
          end
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
      {
        rating: weighted_rating[:rating] / weighted_rating[:total],
        reasons: reasons
      }
    end

    # Sumoner personal performance against that champion compared to the overall matchup
    # for those champions
    def champion_matchup_performance(args)
      factors = {}
      queue = args[:summoner].queue(RankedQueue::SOLO_QUEUE)
      champion_gg_role = ChampionGGApi::MATCHUP_ROLES[args[:role].to_sym]
      matchup = Matchup.new(
        name1: args[:champion].name,
        name2: args[:champion2].name,
        elo: queue.elo,
        role1: champion_gg_role,
        role2: champion_gg_role
      )
      matchup_performances = args[:performances].where(champion_id: args[:champion].id, role: args[:role]).select { |performance| performance.opponent.champion_id == args[:champion2].id }

      # If they have never played against the opposing champion ever as that champion
      # then overall this matchup factor is significant factor and add associated risk
      if matchup_performances.empty?
        factors[:MATCHUP_NO_EXPERIENCE] = {
          priority: PRIORITIES[:HIGHEST],
          performance: INEXPERIENCE_MULTIPLIER
        }
        priority = PRIORITIES[:HIGHEST]
      # If they have not played against that champion much then overall this matchup
      # factor is not as significant but there is inexperience risk
      else
        if matchup_performances.length < MINIMUM_PERFORMANCES
          factors[:MATCHUP_INEXPERIENCE] = {
            priority: PRIORITIES[:HIGHEST],
            args: {
              total: matchup_performances.length
            },
            performance: INEXPERIENCE_MULTIPLIER * matchup_performances.length
          }
          priority = PRIORITIES[:HIGH]
        else
          priority = PRIORITIES[:HIGHEST]
        end

        own_kda = SummonerPerformance.aggregate_performance_metric(
          matchup_performances,
          RiotApi::RiotApi::POSITION_METRICS[:KDA].to_sym
        )

        aggregate_positions = SummonerPerformance.aggregate_performance_positions(
          matchup_performances, [:gold_earned, :total_minions_killed]
        ).inject({}) do |acc, (position, values)|
          acc.tap do
            acc[position] = (values.sum / matchup_performances.length.to_f).round(2)
          end
        end
      end

      if matchup.valid?
        average_kda = {
          kills: matchup.position('kills', matchup.name1),
          deaths: matchup.position('deaths', matchup.name1),
          assists: matchup.position('assists', matchup.name1)
        }
      # If this is not a common matchup overall then add a factor for that risk
      # but lower the priority of this overall matchup factor since there is not
      # much data on it either way
      else
        factors[:OFF_META_MATCHUP_FACTOR] = {
          priority: PRIORITIES[:HIGHEST],
          performance: OFF_META_MATCHUP_FACTOR
        }
        priority = PRIORITIES[:MEDIUM]
      end

      # If it is a meta matchup and they have played it before compare them to the meta
      if matchup.valid? && matchup_performances.present?
        factors.merge!({
          MATCHUP_WIN_RATE: win_rate({
            own: SummonerPerformance.winrate(matchup_performances),
            opposing: (matchup.position('winrate', matchup.name1) * 100).round(2)
          }),
          MATCHUP_KDA: kda({
            own: (own_kda[:kills] + own_kda[:assists]) / own_kda[:deaths].to_f,
            opposing: (average_kda[:kills] + average_kda[:assists]) / average_kda[:deaths].to_f
          }),
          MATCHUP_CS: cs({
            own: aggregate_positions[:total_minions_killed],
            opposing: matchup.position('minionsKilled', matchup.name1)
          }),
          MATCHUP_GOLD: gold({
            own: aggregate_positions[:gold_earned],
            opposing: matchup.position('goldEarned', matchup.name1)
          })
        })
      # If it is meta matchup but they have not played it, compare the meta performance
      # to some constants
      elsif matchup.valid?
        factors.merge!({
          AVERAGE_MATCHUP_WIN_RATE: win_rate({
            own: (matchup.position('winrate', matchup.name1) * 100).round(2),
            opposing: STANDARD_WIN_RATE * 100,
          }),
          AVERAGE_MATCHUP_KDA: kda({
            own: (average_kda[:kills] + average_kda[:assists]) / average_kda[:deaths].to_f,
            opposing: STANDARD_KDA
          }),
        })
      # If it is a non-meta matchup but they have played it then compare their performance
      # to some constants
      elsif matchup_performances.present?
        factors.merge!({
          OFF_META_MATCHUP_WIN_RATE: win_rate({
            own: SummonerPerformance.winrate(matchup_performances),
            opposing: STANDARD_WIN_RATE * 100
          }),
          OFF_META_MATCHUP_KDA: kda({
            own: (own_kda[:kills] + own_kda[:assists]) / own_kda[:deaths].to_f,
            opposing: STANDARD_KDA
          })
        })
      end

      {
        priority: priority,
        factors: factors
      }
    end

    # Whether the summoner is on a winning or losing streak
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
          STREAK: {
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
        priority: PRIORITIES[:HIGH],
        args: comparison,
        performance: win_rate_performance
      }
    end

    def kda(comparison)
      kda_ceiling = comparison[:opposing] * 1.5
      kda_performance = comparison[:own] / kda_ceiling

      {
        priority: PRIORITIES[:MEDIUM],
        args: comparison.inject({}) do |acc, (key, value)|
          acc.tap { acc[key] = value.round(2) }
        end,
        performance: kda_performance
      }
    end

    def cs(comparison)
      {
        priority: PRIORITIES[:LOW],
        args: comparison.inject({}) do |acc, (key, value)|
          acc.tap { acc[key] = value.round(2) }
        end,
        performance: comparison[:own] / comparison[:opposing]
      }
    end

    def gold(comparison)
      {
        priority: PRIORITIES[:LOW],
        args: comparison.inject({}) do |acc, (key, value)|
          acc.tap { acc[key] = value.round(2) }
        end,
        performance: comparison[:own] / comparison[:opposing]
      }
    end

    # Summoner personal performance on that champion compared to the champion's
    # current meta performance
    def champion_performance(args)
      factors = {}
      champion_performances = args[:performances].where(champion_id: args[:champion].id, role: args[:role])

      # If they have not played their champion at all then it heavily weighs that factor
      if champion_performances.empty?
        factors[:CHAMPION_NO_EXPERIENCE] = {
          priority: PRIORITIES[:HIGHEST],
          performance: INEXPERIENCE_MULTIPLIER
        }
        priority = PRIORITIES[:HIGHEST]
      # If they have not played their champion much it heavily weighs that factor
      else
        if champion_performances.length < MINIMUM_PERFORMANCES
          factors[:CHAMPION_INEXPERIENCE] = {
            priority: PRIORITIES[:HIGHEST],
            args: {
              total: champion_performances.length
            },
            performance: INEXPERIENCE_MULTIPLIER * champion_performances.length
          }
          priority = PRIORITIES[:HIGHEST]
        else
          priority = PRIORITIES[:HIGH]
        end

        aggregate_positions = SummonerPerformance.aggregate_performance_positions(
          champion_performances, [:gold_earned, :total_minions_killed]
        ).inject({}) do |acc, (position, values)|
          acc.tap do
            acc[position] = (values.sum / champion_performances.length.to_f).round(2)
          end
        end

        own_kda = SummonerPerformance.aggregate_performance_metric(
          champion_performances,
          RiotApi::RiotApi::POSITION_METRICS[:KDA].to_sym
        )
      end

      champion_gg_role = ChampionGGApi::MATCHUP_ROLES[args[:role].to_sym]
      queue = args[:summoner].queue(RankedQueue::SOLO_QUEUE)
      champion_role_performance = RolePerformance.new(
        elo: queue.elo,
        role: champion_gg_role,
        name: args[:champion].name
      )

      if champion_role_performance.valid?
        average_kda = champion_role_performance.kda
      else
        # If this champion does not overall play this role then factor in risk around
        # playing this champion
        factors[:OFF_META_CHAMPION] = {
          priority: PRIORITIES[:HIGH],
          performance: OFF_META_CHAMPION_FACTOR
        }
      end

      if champion_performances.present? && champion_role_performance.valid?
        factors.merge!({
          CHAMPION_WIN_RATE: win_rate({
            own: SummonerPerformance.winrate(champion_performances),
            opposing: (champion_role_performance.winRate * 100).round(2)
          }),
          CHAMPION_KDA: kda({
            own: (own_kda[:kills] + own_kda[:assists]) / own_kda[:deaths].to_f,
            opposing: (average_kda[:kills] + average_kda[:assists]) / average_kda[:deaths].to_f
          }),
          CHAMPION_CS: cs({
            own: aggregate_positions[:total_minions_killed],
            opposing: champion_role_performance.minionsKilled
          }),
          CHAMPION_GOLD: gold({
            own: aggregate_positions[:gold_earned],
            opposing: champion_role_performance.goldEarned
          })
        })
      elsif champion_performances.present?
        factors.merge!({
          OFF_META_CHAMPION_WIN_RATE: win_rate({
            own: SummonerPerformance.winrate(champion_performances),
            opposing: STANDARD_WIN_RATE * 100
          }),
          OFF_META_CHAMPION_KDA: kda({
            own: (own_kda[:kills] + own_kda[:assists]) / own_kda[:deaths].to_f,
            opposing: STANDARD_KDA
          })
        })
      elsif champion_role_performance.valid?
        factors.merge!({
          AVERAGE_CHAMPION_WIN_RATE: win_rate({
            own: (champion_role_performance.winRate * 100).round(2),
            opposing: STANDARD_WIN_RATE * 100
          }),
          AVERAGE_CHAMPION_KDA: kda({
            own: (average_kda[:kills] + average_kda[:assists]) / average_kda[:deaths].to_f,
            opposing: STANDARD_KDA
          })
        })
      end

      {
        priority: priority,
        factors: factors
      }
    end
  end
end
