class AddBodyToFeaturedIssues < ActiveRecord::Migration
  def change
    add_column :featured_issues, :body, :text
  end
end
