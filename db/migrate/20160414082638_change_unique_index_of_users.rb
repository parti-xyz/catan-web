class ChangeUniqueIndexOfUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :active, :string, default: 'on'

    query = "UPDATE users SET active = (CASE WHEN deleted_at IS NULL THEN 'on' ELSE NULL END)"
    ActiveRecord::Base.connection.execute query
    say query

    remove_index :users, name: "index_users_on_confirmation_token_and_deleted_at"
    remove_index :users, name: "index_users_on_nickname_and_deleted_at"
    remove_index :users, name: "index_users_on_provider_and_uid_and_deleted_at"
    remove_index :users, name: "index_users_on_reset_password_token_and_deleted_at"
    add_index :users, [:confirmation_token, :active], unique: true
    add_index :users, [:nickname, :active], unique: true
    add_index :users, [:provider, :uid, :active], unique: true
    add_index :users, [:reset_password_token, :active], unique: true
  end

  def down
    raise "unimplemented"
  end
end
