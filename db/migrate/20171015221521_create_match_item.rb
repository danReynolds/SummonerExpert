class CreateMatchItem < ActiveRecord::Migration[5.0]
  def change
    create_table :match_items do |t|
      t.timestamps
      t.integer :item_id
      t.integer :summoner_performance_id
    end
  end
end
