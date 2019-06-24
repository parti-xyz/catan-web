class AddFolderSeqToPostsAndFolders < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :folder_seq, :integer, default: 0
    add_column :folders, :folder_seq, :integer, default: 0
  end
end
