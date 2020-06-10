class AddConfirmationGroupSlugToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :confirmation_group_slug, :string
  end
end
