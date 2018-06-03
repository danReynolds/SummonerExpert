class CreateSummonersTable < ActiveRecord::Migration[5.0]
  def change
    create_table :summoners do |t|
      t.string :name
      t.integer :account_id
      t.integer :summoner_id
      t.timestamps
    end
  end
end
