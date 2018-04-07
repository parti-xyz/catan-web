class ClearDirtyActiveIssueStats < ActiveRecord::Migration
  def up
    ActiveIssueStat.where(issue_id: Issue.only_deleted).destroy_all
  end
end
