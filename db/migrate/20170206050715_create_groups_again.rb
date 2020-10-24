class CreateGroupsAgain < ActiveRecord::Migration[4.2]
  def change
    #drop_table :groups

    create_table :groups do |t|
      t.references :user, null: false
      t.string :name, null: false
      t.string :site_title, null: false
      t.string :head_title, null: false
      t.text :site_description, limit: 16.megabytes - 1
      t.text :site_keywords, limit: 16.megabytes - 1
      t.string :slug, null: false
      t.string :logo
      t.string :cover
      t.datetime :deleted_at
      t.string :active, default: 'on'
      t.timestamps null: false
    end

    add_index :groups, [:slug, :active], unique: true
    add_index :groups, [:site_title, :active], unique: true
  end
end
