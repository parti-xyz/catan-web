class CreateDeviceTokens < ActiveRecord::Migration
  def change
    create_table :device_tokens do |t|
      t.references :user, null: false, index: true
      t.string :registration_id, null: false, index: true
      t.timestamps null: false
    end

    add_index :device_tokens, [:user_id, :registration_id], unique: true
  end
end
