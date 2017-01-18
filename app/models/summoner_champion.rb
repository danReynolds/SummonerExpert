class SummonerChampion
  include ActiveModel::Validations

  AGGRESSIVE_PERCENTAGE = 50
  SPLIT_PUSH_CHANCE = 2

  ACCESSORS = [
    :summoner_champion, [:total_wins, :totalSessionsWon],
    [:total_sessions, :totalSessionsPlayed], [:total_first_blood, :totalFirstBlood],
    [:total_turrets, :totalTurretsKilled], [:total_cs, :totalMinionKills],
    [:total_gold, :totalGoldEarned], [:total_deaths, :totalDeathsPerSession],
    [:total_assists, :totalAssists], [:total_kills, :totalChampionKills]
  ].freeze
  ACCESSORS.each do |accessor|
    if accessor.is_a?(Array)
      attr_accessor accessor.first
    else
      attr_accessor accessor
    end
  end

  def initialize(attributes = {})
    stats = attributes[:stats]
    self.class::ACCESSORS.each do |accessor|
      if accessor.is_a?(Array)
        instance_variable_set("@#{accessor.first}", stats[accessor.last])
      else
        instance_variable_set("@#{accessor}", stats[accessor])
      end
    end
  end

  def kda
    "#{@total_kills / @total_sessions}/#{@total_deaths / @total_sessions}/" \
    "#{@total_assists / @total_sessions}"
  end

  def first_blood
    (@total_first_blood / @total_sessions.to_f * 100).round
  end

  def towers
    @total_turrets / @total_sessions
  end

  def cs
    @total_cs / @total_sessions
  end

  def gold
    @total_gold / @total_sessions
  end

  def win_rate
    (@total_wins / @total_sessions.to_f * 100).round(2)
  end
end
