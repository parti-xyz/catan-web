class CreateGroupsAgain < ActiveRecord::Migration
  def change
    drop_table :groups

    create_table :groups, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC" do |t|
      t.references :user, null: false
      t.string :name, null: false
      t.string :site_title, null: false
      t.string :head_title, null: false
      t.text :site_description
      t.text :site_keywords
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
