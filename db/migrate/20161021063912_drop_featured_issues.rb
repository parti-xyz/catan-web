class DropFeaturedIssues < ActiveRecord::Migration[4.2]
  def change
  	drop_table :featured_issues
  end
end
