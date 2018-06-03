class AddMatchDurationToMatch < ActiveRecord::Migration[5.0]
  def change
    add_column :matches, :game_duration, :integer
  end
end
