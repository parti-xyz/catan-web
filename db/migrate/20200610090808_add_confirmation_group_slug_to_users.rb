class AddConfirmationGroupSlugToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :touch_group_slug, :string
  end
end
