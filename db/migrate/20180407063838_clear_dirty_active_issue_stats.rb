class ClearDirtyActiveIssueStats < ActiveRecord::Migration[4.2]
  def up
    ActiveIssueStat.where(issue_id: Issue.only_deleted).destroy_all
  end
end
