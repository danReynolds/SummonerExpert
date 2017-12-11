class AddItemsToSummonerPerformance < ActiveRecord::Migration[5.0]
  def change
    add_column :summoner_performances, :item0_id, :integer
    add_column :summoner_performances, :item1_id, :integer
    add_column :summoner_performances, :item2_id, :integer
    add_column :summoner_performances, :item3_id, :integer
    add_column :summoner_performances, :item4_id, :integer
    add_column :summoner_performances, :item5_id, :integer
    add_column :summoner_performances, :item6_id, :integer
  end
end
