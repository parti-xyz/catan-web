class RemoveFeedbacksCounts < ActiveRecord::Migration
  def change
    remove_column :options, :feedbacks_counts
    remove_column :surveys, :feedbacks_counts
  end
end
