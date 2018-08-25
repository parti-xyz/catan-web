class ChangeLengthOfPostsDecision < ActiveRecord::Migration[5.2]
  def change
    change_column :posts, :decision, :text, limit: 16777215
  end
end
