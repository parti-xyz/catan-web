class AddOmniauthToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :provider, :string, default: 'email', null: false
    add_column :users, :uid, :string

    query = "UPDATE users SET uid = email"
    ActiveRecord::Base.connection.execute query
    say query

    change_column_null :users, :uid, false

    remove_index :users, :email
    add_index :users, [:provider, :uid], unique: true
  end

  def down
    raise "unimplemented"
  end
end
