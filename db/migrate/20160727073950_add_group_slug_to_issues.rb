class AddGroupSlugToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :group_slug, :string
  end
end
