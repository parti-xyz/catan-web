class AddGroupSlugToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :group_slug, :string
  end
end
