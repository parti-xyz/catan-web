class AddNewMembersCountToActiveIssueStats < ActiveRecord::Migration[4.2]
  def change
    add_column :active_issue_stats, :new_members_count, :integer, default: 0
  end
end
