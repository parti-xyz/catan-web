class AddSourceGroupSlugToMergedIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :merged_issues, :source_group_slug, :string
  end
end
