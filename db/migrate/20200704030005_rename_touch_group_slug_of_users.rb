class RenameTouchGroupSlugOfUsers < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :confirmation_group_slug, :touch_group_slug
  end
end
