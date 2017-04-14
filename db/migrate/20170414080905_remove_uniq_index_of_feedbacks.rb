class RemoveUniqIndexOfFeedbacks < ActiveRecord::Migration
  def change
    remove_index :feedbacks, ["user_id", "survey_id"]
    add_index :feedbacks, ["user_id", "option_id"], unique: true
  end
end
