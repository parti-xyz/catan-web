class AddSourceGroupSlugToMergedIssues < ActiveRecord::Migration
  def change
    add_column :merged_issues, :source_group_slug, :string
  end
end
