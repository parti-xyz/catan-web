class ChangeIssueToMakableOfMakers < ActiveRecord::Migration
  def up
    rename_column :makers, :issue_id, :makable_id
    add_column :makers, :makable_type, :string, null: true
    add_index :makers, [:makable_id, :makable_type]

    query = <<-SQL.squish
      UPDATE makers SET makable_type = 'Issue'
    SQL
    ActiveRecord::Base.connection.execute query
    change_column_null :makers, :makable_type, false
  end
  def down
    raise '다운그레이드는 지원하지 않습니다'
  end
end


