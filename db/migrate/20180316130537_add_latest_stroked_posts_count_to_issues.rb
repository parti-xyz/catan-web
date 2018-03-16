class AddLatestStrokedPostsCountToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :latest_stroked_posts_count, :integer
    add_column :issues, :latest_stroked_posts_count_version, :integer

    reversible do |dir|
      dir.up do
        LastStrokedPostsCountJob.new.perform
      end
    end
  end
end
