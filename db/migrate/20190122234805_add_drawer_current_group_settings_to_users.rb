class AddDrawerCurrentGroupSettingsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :drawer_current_group_fixed_top, :boolean, default: false
    add_column :users, :drawer_current_group_unfold_only, :boolean, default: false
  end
end
