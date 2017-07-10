class RecreateWikiHistories < ActiveRecord::Migration
  def up
    drop_table :wiki_histories
    create_table :wiki_histories, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC" do |t|
      t.string :title, null: false
      t.references :wiki, null: false, index: true
      t.references :user, null: false, index: true
      t.text :body, limit: 16777215
      t.string :code, null: false
      t.timestamps nill: false
    end
  end

  def down
  end
end
