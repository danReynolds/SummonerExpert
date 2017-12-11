class CreateMatchTable < ActiveRecord::Migration[5.0]
  def change
    create_table :matches do |t|
      t.timestamps
      t.integer :game_id
      t.integer :queue_id
      t.integer :season_id
      t.integer :region_id
      t.integer :winning_team_id
      t.integer :first_blood_id
      t.integer :first_tower_id
      t.integer :first_inhibitor_id
      t.integer :first_baron_id
      t.integer :first_rift_herald_id
      t.integer :team1_id
      t.integer :team2_id
      t.integer :first_blood_summoner_id
      t.integer :first_tower_summoner_id
      t.integer :first_inhibitor_summoner_id
    end
  end
end
