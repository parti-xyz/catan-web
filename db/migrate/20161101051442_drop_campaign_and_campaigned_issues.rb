class DropCampaignAndCampaignedIssues < ActiveRecord::Migration
  def change
    drop_table :campaigns
    drop_table :campaigned_issues
  end
end
