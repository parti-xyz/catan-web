class AddLatestStrokedPostsCountAndLatestIssuesCountToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :latest_stroked_posts_count, :integer, default: 0
    add_column :groups, :latest_stroked_posts_count_version, :integer, default: 0
    add_column :groups, :latest_issues_count, :integer, default: 0
    add_column :groups, :latest_issues_count_version, :integer, default: 0
  end
end
