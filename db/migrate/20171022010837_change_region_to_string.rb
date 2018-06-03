class ChangeRegionToString < ActiveRecord::Migration[5.0]
  def change
    change_column :matches, :region_id, :string
  end
end
