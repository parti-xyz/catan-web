class ModifyLatestStrokedPostsCountsOfIssues < ActiveRecord::Migration
  def change
    change_column :issues, :latest_stroked_posts_count, :integer, default: 0

    reversible do |dir|
      dir.up do
        query = "UPDATE issues SET latest_stroked_posts_count = 0"
        ActiveRecord::Base.connection.execute query
        say query
      end
    end
  end
end
