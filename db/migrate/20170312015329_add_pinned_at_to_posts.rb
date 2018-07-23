class AddPinnedAtToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :pinned_at, :datetime
  end
end
