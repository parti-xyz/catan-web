class AlterNullableIssueOfBlinds < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:blinds, :issue_id, true)
  end
end
