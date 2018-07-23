class AddFolderToPosts < ActiveRecord::Migration[4.2]
  def change
    add_reference :posts, :folder, null: true, index: true
  end
end
