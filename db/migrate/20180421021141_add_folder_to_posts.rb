class AddFolderToPosts < ActiveRecord::Migration
  def change
    add_reference :posts, :folder, null: true, index: true
  end
end
