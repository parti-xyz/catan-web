class RemoveCampaignOfIssues < ActiveRecord::Migration
  def change
    remove_column :issues, :campaign_id
  end
end
