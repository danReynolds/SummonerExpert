class IndexForeignKeysInTeams < ActiveRecord::Migration
  def change
    add_index :teams, :team_id
  end
end
