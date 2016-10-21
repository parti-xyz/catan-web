class DropFeaturedIssues < ActiveRecord::Migration
  def change
  	drop_table :featured_issues
  end
end
