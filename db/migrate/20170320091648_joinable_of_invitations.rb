class JoinableOfInvitations < ActiveRecord::Migration
  def up
    rename_column :invitations, :issue_id, :joinable_id
    add_column :invitations, :joinable_type, :string, null: true
    add_index :invitations, [:joinable_id, :joinable_type]
    add_index "invitations", ["user_id", "recipient_id", "joinable_id", "joinable_type"], name: :unique_index_invitations, unique: true

    query = <<-SQL.squish
      UPDATE invitations SET joinable_type = 'Issue'
    SQL
    ActiveRecord::Base.connection.execute query
    change_column_null :invitations, :joinable_type, false
  end

  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
