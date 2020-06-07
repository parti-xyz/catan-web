class CreateStrokedPostUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :stroked_post_users do |t|
      t.references :user
      t.references :post
      t.timestamps null: false
    end
  end
end
