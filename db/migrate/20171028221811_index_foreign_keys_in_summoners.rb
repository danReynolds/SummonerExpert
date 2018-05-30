class IndexForeignKeysInSummoners < ActiveRecord::Migration
  def change
    add_index :summoners, :account_id
    add_index :summoners, :summoner_id, unique: true
    add_index :summoners, :name, unique: true
  end
end
