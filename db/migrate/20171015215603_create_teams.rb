class CreateTeams < ActiveRecord::Migration[5.0]
  def change
    create_table :teams do |t|
      t.timestamps
      t.integer :match_id
      t.integer :team_id
      t.integer :tower_kills
      t.integer :inhibitor_kills
      t.integer :baron_kills
      t.integer :dragon_kills
      t.integer :riftherald_kills
    end
  end
end
