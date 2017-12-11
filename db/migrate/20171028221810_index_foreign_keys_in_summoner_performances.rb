class IndexForeignKeysInSummonerPerformances < ActiveRecord::Migration
  def change
    add_index :summoner_performances, :champion_id
    add_index :summoner_performances, :item0_id
    add_index :summoner_performances, :item1_id
    add_index :summoner_performances, :item2_id
    add_index :summoner_performances, :item3_id
    add_index :summoner_performances, :item4_id
    add_index :summoner_performances, :item5_id
    add_index :summoner_performances, :item6_id
    add_index :summoner_performances, :match_id
    add_index :summoner_performances, :participant_id
    add_index :summoner_performances, :spell1_id
    add_index :summoner_performances, :spell2_id
    add_index :summoner_performances, :summoner_id
    add_index :summoner_performances, :team_id
  end
end
