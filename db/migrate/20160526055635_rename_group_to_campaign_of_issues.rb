class RenameGroupToCampaignOfIssues < ActiveRecord::Migration
  def change
    rename_column :issues, :group_id, :campaign_id
  end
end
