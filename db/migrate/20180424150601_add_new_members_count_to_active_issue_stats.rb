class AddNewMembersCountToActiveIssueStats < ActiveRecord::Migration
  def change
    add_column :active_issue_stats, :new_members_count, :integer, default: 0
  end
end
