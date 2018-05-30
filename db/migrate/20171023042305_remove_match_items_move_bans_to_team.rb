class RemoveMatchItemsMoveBansToTeam < ActiveRecord::Migration[5.0]
  def change
    drop_table :match_items
    remove_column :bans, :match_id
    add_column :bans, :team_id, :integer
  end
end
