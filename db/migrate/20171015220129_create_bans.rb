class CreateBans < ActiveRecord::Migration[5.0]
  def change
    create_table :bans do |t|
      t.timestamps
      t.integer :champion_id
      t.integer :order
      t.integer :match_id
    end
  end
end
