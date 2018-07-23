class AddLastCommentedAtToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :last_commented_at, :datetime
  end
end
