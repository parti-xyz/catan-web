class RemoveUniqIndexOfFeedbacks < ActiveRecord::Migration[4.2]
  def change
    remove_index :feedbacks, ["user_id", "survey_id"]
    add_index :feedbacks, ["user_id", "option_id"], unique: true
  end
end
