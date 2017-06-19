class AddJoinedIssuesUpdatedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :member_issues_changed_at, :datetime

    query = <<-SQL.squish
      UPDATE users SET member_issues_changed_at = now()
    SQL
    ActiveRecord::Base.connection.execute query
  end
end
