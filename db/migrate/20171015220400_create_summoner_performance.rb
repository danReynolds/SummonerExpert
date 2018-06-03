class CreateSummonerPerformance < ActiveRecord::Migration[5.0]
  def change
    create_table :summoner_performances do |t|
      t.timestamps
      t.integer :team_id
      t.integer :summoner_id
      t.integer :match_id
      t.integer :participant_id
      t.integer :champion_id
      t.integer :spell1_id
      t.integer :spell2_id
      t.integer :kills
      t.integer :deaths
      t.integer :assists
      t.string  :role
      t.string  :lane
      t.integer :largest_killing_spree
      t.integer :total_killing_sprees
      t.integer :longest_time_alive
      t.integer :double_kills
      t.integer :triple_kills
      t.integer :quadra_kills
      t.integer :penta_kills
      t.integer :total_damage_dealt
      t.integer :magic_damage_dealt
      t.integer :physical_damage_dealt
      t.integer :true_damage_dealt
      t.integer :largest_critical_strike
      t.integer :total_damage_dealt_to_champions
      t.integer :magic_damage_dealt_to_champions
      t.integer :physical_damage_dealt_to_champions
      t.integer :true_damage_dealt_to_champions
      t.integer :total_healing_done
      t.integer :vision_score
      t.integer :cc_score
      t.integer :gold_earned
      t.integer :turrets_killed
      t.integer :inhibitors_killed
      t.integer :total_minions_killed
      t.integer :vision_wards_bought
      t.integer :sight_wards_bought
      t.integer :wards_placed
      t.integer :wards_killed
      t.integer :neutral_minions_killed
    end
  end
end
