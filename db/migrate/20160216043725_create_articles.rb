class CreateArticles < ActiveRecord::Migration[4.2]
  def change
    create_table :articles do |t|
      t.references :user, null: false, index: true
      t.string :title, null: false
      t.text :body
      t.string :link, length: 1000
      t.references :issue, null: false, index: true
      t.timestamps null: false
    end
  end
end
