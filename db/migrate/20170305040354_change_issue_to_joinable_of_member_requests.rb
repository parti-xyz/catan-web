class ChangeIssueToJoinableOfMemberRequests < ActiveRecord::Migration[4.2]
  def up
    remove_index :member_requests, [:issue_id, :user_id, :active]
    remove_index :member_requests, [:issue_id]

    rename_column :member_requests, :issue_id, :joinable_id
    add_column :member_requests, :joinable_type, :string, null: true
    add_index :member_requests, [:joinable_id, :joinable_type]

    query = <<-SQL.squish
      UPDATE member_requests
         SET joinable_type = 'Issue'
    SQL
    ActiveRecord::Base.connection.execute query
    change_column_null :member_requests, :joinable_type, false

    add_index :member_requests, [:joinable_id, :joinable_type, :user_id, :active], unique: true, name: :unique_member_requests
  end
  def down
    raise '다운그레이드는 지원하지 않습니다'
  end
end
