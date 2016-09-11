class AddAuthenticationTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :authentication_token, :string, index: true
    add_column :users, :authentication_token_created_at, :datetime, null: true
  end
end
