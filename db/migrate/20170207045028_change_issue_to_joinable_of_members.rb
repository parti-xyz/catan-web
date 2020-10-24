class ChangeIssueToJoinableOfMembers < ActiveRecord::Migration[4.2]
  class Member < ApplicationRecord
  end

  def up
    rename_column :members, :issue_id, :joinable_id
    add_column :members, :joinable_type, :string, null: true
    add_index :members, [:joinable_id, :joinable_type]

    Member.update_all(joinable_type: 'Issue')
    change_column_null :members, :joinable_type, false
  end
  def down
    raise '다운그레이드는 지원하지 않습니다'
  end
end
