class AddBodyToFeaturedIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :featured_issues, :body, :text
  end
end
