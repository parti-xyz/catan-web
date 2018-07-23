class AddLastTouchedAtToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :last_touched_at, :datetime

    reversible do |dir|
      dir.up do
        Post.with_deleted.all.each do |post|
          post.update_columns(last_touched_at: post.last_commented_at.presence || post.created_at)
        end
      end
    end

  end
end
