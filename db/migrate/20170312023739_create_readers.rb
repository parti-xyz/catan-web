class CreateReaders < ActiveRecord::Migration
  def change
    create_table :readers do |t|
      t.references :post, index: true, null: false
      t.references :member, index: true, null: false
      t.timestamps null: false
      t.index [:post_id, :member_id], unique: true
    end
  end
end
