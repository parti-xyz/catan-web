class CreateWikiHistories < ActiveRecord::Migration[4.2]
  def change
    create_table :wiki_histories do |t|
      t.references :user, null: false, index: true
      t.references :wiki, null: false, index: true
      t.text :body, limit: 160.megabytes - 1
      t.timestamps
    end
  end
end
