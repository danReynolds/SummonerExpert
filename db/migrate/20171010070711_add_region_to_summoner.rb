class AddRegionToSummoner < ActiveRecord::Migration[5.0]
  def change
    add_column :summoners, :region, :string
  end
end
