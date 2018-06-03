class ChangeSummonerPerformancesColumnSize < ActiveRecord::Migration[5.0]
  def up
    change_column :summoner_performances, :id, :integer, limit: 8
    change_column :bans, :id, :integer, limit: 8
    change_column :bans, :summoner_performance_id, :integer, limit: 8
    change_column :teams, :id, :integer, limit: 8
    change_column :summoners, :account_id, :integer, limit: 8
  end
end
