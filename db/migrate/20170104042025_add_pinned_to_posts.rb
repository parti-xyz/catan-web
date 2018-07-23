class AddPinnedToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :pinned, :boolean, default: false
  end
end
