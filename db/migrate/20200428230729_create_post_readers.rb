class CreatePostReaders < ActiveRecord::Migration[5.2]
  def change
    create_table :post_readers do |t|
      t.references :user, null: false, index: true
      t.references :post, null: false, index: true
      t.timestamps null: false
    end
  end
end
