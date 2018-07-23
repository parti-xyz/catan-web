class RecreateWikis < ActiveRecord::Migration[4.2]
  def up
    drop_table :wikis
    create_table :wikis, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC" do |t|
      t.string :title, null: false
      t.text :body, limit: 16777215
      t.string :thumbnail
      t.datetime :deleted_at
      t.references :last_author, null: true, index: true
      t.timestamps nill: false
    end
  end

  def down
  end
end
