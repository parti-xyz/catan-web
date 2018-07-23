class RemoveFeedbacksCounts < ActiveRecord::Migration[4.2]
  def change
    remove_column :options, :feedbacks_counts
    remove_column :surveys, :feedbacks_counts
  end
end
