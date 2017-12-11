class IndexForeignKeysInBans < ActiveRecord::Migration
  def change
    add_index :bans, :champion_id
    add_index :bans, :summoner_performance_id, unique: true
  end
end
