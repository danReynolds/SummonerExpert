class SummonerPerformance < ActiveRecord::Base
  include RiotApi
  belongs_to :team
  belongs_to :summoner
  belongs_to :match
  has_one :ban

  validates_presence_of :team_id, :summoner_id, :match_id, :participant_id,
    :champion_id, :spell1_id, :spell2_id, :kills, :deaths, :assists, :role,
    :largest_killing_spree, :total_killing_sprees, :double_kills, :triple_kills,
    :quadra_kills, :penta_kills, :total_damage_dealt, :magic_damage_dealt,
    :physical_damage_dealt, :true_damage_dealt, :largest_critical_strike,
    :total_damage_dealt_to_champions, :magic_damage_dealt_to_champions,
    :physical_damage_dealt_to_champions, :true_damage_dealt_to_champions,
    :total_healing_done, :vision_score, :cc_score, :gold_earned, :turrets_killed,
    :inhibitors_killed, :total_minions_killed, :vision_wards_bought,
    :sight_wards_bought, :wards_placed, :wards_killed, :neutral_minions_killed,
    :neutral_minions_killed_team_jungle, :neutral_minions_killed_enemy_jungle

  class << self
    def winrate(performances)
      (performances.select(&:victorious?).count / performances.count.to_f * 100).round(2)
    end

    def aggregate_performance_positions(performances, positions)
      performances.inject({}) do |acc, performance|
        acc.tap do
          positions.each do |position|
            acc[position] ||= []
            acc[position] << performance.send(position)
          end
        end
      end
    end

    def aggregate_performance_metric(performances, metric)
      case metric
      when :count
        { count: performances.count }
      when :winrate
        { winrate: performances.select(&:victorious?).length / performances.length.to_f * 100 }
      when :KDA
        aggregate_performance_positions(performances, [:kills, :deaths, :assists]).inject({}) do |acc, (metric, value)|
          acc.tap do
            acc[metric] = value.sum / value.count.to_f
          end
        end
      end
    end
  end

  def kda
    (kills + assists) / deaths.to_f
  end

  def victorious?
    team_id == match.winning_team_id
  end

  def items
    ids_to_names = Cache.get_collection(:items)
    [item0_id, item1_id, item2_id, item3_id, item4_id, item5_id].compact.map do |item_id|
      item_name = ids_to_names[item_id]
      Item.new(name: item_name) if item_name
    end.compact
  end

  def full_build?
    items.length == RiotApi::COMPLETED_BUILD_SIZE && items.all?(&:complete?)
  end

  def opponent
    match.summoner_performances.find do |performance|
      performance.role == role && performance != self
    end
  end
end
