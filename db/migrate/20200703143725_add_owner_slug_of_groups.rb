class AddOwnerSlugOfGroups < ActiveRecord::Migration[5.2]
  def change
    remove_column :groups, :cloud_plan

    add_column :groups, :owner_slug, :string, default: 'default'
  end
end
