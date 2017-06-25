class AddJoinedIssuesUpdatedAtToUsers < ActiveRecord::Migration
  def up
    add_column :users, :member_issues_changed_at, :datetime

    reversible do |dir|
      dir.up do
        query = <<-SQL.squish
          UPDATE users SET member_issues_changed_at = now()
        SQL
        ActiveRecord::Base.connection.execute query
      end
    end
  end
  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
