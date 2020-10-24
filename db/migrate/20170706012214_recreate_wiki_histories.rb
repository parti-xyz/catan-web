class RecreateWikiHistories < ActiveRecord::Migration[4.2]
  def up
    drop_table :wiki_histories
    create_table :wiki_histories do |t|
      t.string :title, null: false
      t.references :wiki, null: false, index: true
      t.references :user, null: false, index: true
      t.text :body, limit: 160.megabytes - 1
      t.string :code, null: false
      t.timestamps nill: false
    end
  end

  def down
  end
end
