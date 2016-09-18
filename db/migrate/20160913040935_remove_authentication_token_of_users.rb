class RemoveAuthenticationTokenOfUsers < ActiveRecord::Migration
  def change
    remove_column :users, :authentication_token, :string, index: true
    remove_column :users, :authentication_token_created_at, :datetime, null: true
  end
end
