class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table :comments do |t|
      t.references :user, null: false, index: true
      t.references :post, null: false, index: true
      t.text :body, limit: 16.megabytes - 1
      t.timestamps null: false
    end
  end
end
