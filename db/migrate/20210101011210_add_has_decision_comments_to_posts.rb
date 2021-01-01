class AddHasDecisionCommentsToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :has_decision_comments, :boolean, default: false
  end
end
