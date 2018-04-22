class CreateFolders < ActiveRecord::Migration
  def change
    create_table :folders do |t|
      t.references :user, index: true, null: true
      t.references :issue, index: true, null: false
      t.string :title, index: true, null: false
      t.timestamps null: false
    end

    add_index :folders, [:issue_id, :title], unique: true
  end
end
