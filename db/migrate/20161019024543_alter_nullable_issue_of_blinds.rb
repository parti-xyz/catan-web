class AlterNullableIssueOfBlinds < ActiveRecord::Migration
  def change
    change_column_null(:blinds, :issue_id, true)
  end
end
