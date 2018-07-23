# This migration comes from parti_sso_client (originally 20160103003442)
class CreatePartiSsoClientApiKeys < ActiveRecord::Migration[4.2]
  def change
    create_table :parti_sso_client_api_keys do |t|
      t.references :user, null: false
      t.string :digest, null: false
      t.string :client, null: false, index: true
      t.integer :authentication_id, null: false
      t.datetime :expires_at, null: false
      t.datetime :last_access_at, null: false
      t.boolean :is_locked, null: false, default: false
      t.timestamps null: false
    end

    add_index :parti_sso_client_api_keys, [:user_id, :client], unique: true
  end
end
