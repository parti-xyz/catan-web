class RemoveCampaignOfIssues < ActiveRecord::Migration[4.2]
  def change
    remove_column :issues, :campaign_id
  end
end
