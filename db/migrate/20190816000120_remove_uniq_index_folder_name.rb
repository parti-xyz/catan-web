class RemoveUniqIndexFolderName < ActiveRecord::Migration[5.2]
  def change
    remove_index :folders, name: :index_folders_on_issue_id_and_title
  end
end
