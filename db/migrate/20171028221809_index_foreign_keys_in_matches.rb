class IndexForeignKeysInMatches < ActiveRecord::Migration
  def change
    add_index :matches, :first_baron_id, unique: true
    add_index :matches, :first_blood_id, unique: true
    add_index :matches, :first_blood_summoner_id
    add_index :matches, :first_inhibitor_id, unique: true
    add_index :matches, :first_inhibitor_summoner_id
    add_index :matches, :first_rift_herald_id, unique: true
    add_index :matches, :first_tower_id, unique: true
    add_index :matches, :first_tower_summoner_id
    add_index :matches, :game_id, unique: true
    add_index :matches, :queue_id
    add_index :matches, :region_id
    add_index :matches, :season_id
    add_index :matches, :team1_id, unique: true
    add_index :matches, :team2_id, unique: true
    add_index :matches, :winning_team_id, unique: true
  end
end
