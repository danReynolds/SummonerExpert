class ChangeLongIdColumnsToBigInts < ActiveRecord::Migration[5.0]
  def change
    change_column :matches, :game_id, :bigint
    change_column :summoner_performances, :summoner_id, :bigint
    change_column :summoners, :summoner_id, :bigint
  end
end
