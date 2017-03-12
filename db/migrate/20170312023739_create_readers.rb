class CreateReaders < ActiveRecord::Migration
  def change
    create_table :readers do |t|
      t.references :post, index: true, null: false
      t.references :user, index: true, null: false
      t.timestamps null: false
      t.index [:post_id, :user_id], unique: true
    end
  end
end
