class AddLatestStrokedPostsCountAndLatestIssuesCountToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :latest_stroked_posts_count, :integer, default: 0
    add_column :groups, :latest_stroked_posts_count_version, :integer, default: 0
    add_column :groups, :latest_issues_count, :integer, default: 0
    add_column :groups, :latest_issues_count_version, :integer, default: 0
  end
end
