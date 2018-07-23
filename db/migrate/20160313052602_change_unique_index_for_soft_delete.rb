class ChangeUniqueIndexForSoftDelete < ActiveRecord::Migration[4.2]
  def change
    remove_index :issues, column: :slug, unique: true
    add_index :issues, [:slug, :deleted_at], unique: true

    remove_index :users, column: :confirmation_token, unique: true
    remove_index :users, column: :nickname, unique: true
    remove_index :users, column: [:provider, :uid], unique: true
    remove_index :users, column: :reset_password_token, unique: true

    add_index :users, [:confirmation_token, :deleted_at], unique: true
    add_index :users, [:nickname, :deleted_at], unique: true
    add_index :users, [:provider, :uid, :deleted_at], unique: true
    add_index :users, [:reset_password_token, :deleted_at], unique: true
  end
end
