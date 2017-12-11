class Team < ActiveRecord::Base
  has_many :summoner_performances
  has_one :match, ->(team) { Match.where(team1: team).or(Match.where(team2: team)).first }

  validates_presence_of :team_id, :tower_kills, :inhibitor_kills, :baron_kills,
    :dragon_kills, :riftherald_kills
end
