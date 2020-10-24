class RecreateWikis < ActiveRecord::Migration[4.2]
  def up
    drop_table :wikis
    create_table :wikis do |t|
      t.string :title, null: false
      t.text :body, limit: 160.megabytes - 1
      t.string :thumbnail
      t.datetime :deleted_at
      t.references :last_author, null: true, index: true
      t.timestamps nill: false
    end
  end

  def down
  end
end
