class AddPinnedAtToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :pinned_at, :datetime
  end
end
