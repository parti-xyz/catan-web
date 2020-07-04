class RenameOrganizationSlugOfGroups < ActiveRecord::Migration[5.2]
  def change
    rename_column :groups, :owner_slug, :organization_slug
  end
end
