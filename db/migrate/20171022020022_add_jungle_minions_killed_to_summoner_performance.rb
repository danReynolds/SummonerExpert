class AddJungleMinionsKilledToSummonerPerformance < ActiveRecord::Migration[5.0]
  def change
    add_column :summoner_performances, :neutral_minions_killed_team_jungle, :integer
    add_column :summoner_performances, :neutral_minions_killed_enemy_jungle, :integer
  end
end
