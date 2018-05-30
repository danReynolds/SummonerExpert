class RemoveMatchIdFromTeam < ActiveRecord::Migration[5.0]
  def change
    remove_column :teams, :match_id
  end
end
