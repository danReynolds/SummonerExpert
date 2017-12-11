class AddSummonerPerformanceToBan < ActiveRecord::Migration[5.0]
  def change
    add_column :bans, :summoner_performance_id, :integer
    remove_column :bans, :team_id
  end
end
