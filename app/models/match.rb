class Match < ActiveRecord::Base
  belongs_to :team1, class_name: 'Team', foreign_key: :team1_id
  belongs_to :team2, class_name: 'Team', foreign_key: :team2_id
  belongs_to :winning_team, class_name: 'Team', foreign_key: :winning_team_id
  belongs_to :first_blood_team, class_name: 'Team', foreign_key: :first_blood_id
  belongs_to :first_tower_team, class_name: 'Team', foreign_key: :first_tower_id
  belongs_to :first_inhibitor_team, class_name: 'Team', foreign_key: :first_inhibitor_id
  belongs_to :first_baron_team, class_name: 'Team', foreign_key: :first_baron_id
  belongs_to :first_rift_herald_team, class_name: 'Team', foreign_key: :first_rift_herald_id
  belongs_to :first_blood_summoner, class_name: 'Summoner', foreign_key: :first_blood_summoner_id
  belongs_to :first_tower_summoner, class_name: 'Summoner', foreign_key: :first_tower_summoner_id
  belongs_to :first_inhibitor_summoner, class_name: 'Summoner', foreign_key: :first_inhibitor_summoner_id
  has_many :summoner_performances
  has_many :summoners, through: :summoner_performances

  validates_presence_of :game_id, :queue_id, :season_id, :region_id, :winning_team_id,
    :team1_id, :team2_id, :game_duration

  REMAKE_DURATION = 4.minutes.seconds.to_int
end
