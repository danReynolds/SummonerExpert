class CreateFeedback < ActiveRecord::Migration[5.0]
  def change
    create_table :feedbacks do |t|
      t.timestamps
      t.string :message
      t.string :feedback_type
    end
  end
end
