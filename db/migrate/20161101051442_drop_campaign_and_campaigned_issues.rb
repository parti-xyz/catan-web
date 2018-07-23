class DropCampaignAndCampaignedIssues < ActiveRecord::Migration[4.2]
  def change
    drop_table :campaigns
    drop_table :campaigned_issues
  end
end
