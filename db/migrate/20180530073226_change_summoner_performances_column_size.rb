class ChangeSummonerPerformancesColumnSize < ActiveRecord::Migration[5.0]
  def up
    change_column :summoners, :account_id, :integer, limit: 8
  end
end
