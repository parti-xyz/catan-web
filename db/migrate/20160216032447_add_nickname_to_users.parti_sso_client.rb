# This migration comes from parti_sso_client (originally 20151216185713)
class AddNicknameToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :nickname, :string

    add_index :users, :nickname, unique: true
    reversible do |dir|
      dir.up do
        query = 'UPDATE users SET nickname = id'
        ActiveRecord::Base.connection.execute query
        say query

        change_column_null :users, :nickname, false
      end
    end
  end
end
