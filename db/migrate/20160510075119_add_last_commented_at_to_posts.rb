class AddLastCommentedAtToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :last_commented_at, :datetime
  end
end
