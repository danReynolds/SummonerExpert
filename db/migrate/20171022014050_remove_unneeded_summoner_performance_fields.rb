class RemoveUnneededSummonerPerformanceFields < ActiveRecord::Migration[5.0]
  def change
    remove_column :summoner_performances, :lane
    remove_column :summoner_performances, :longest_time_alive
  end
end
