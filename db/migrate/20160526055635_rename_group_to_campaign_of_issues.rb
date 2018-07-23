class RenameGroupToCampaignOfIssues < ActiveRecord::Migration[4.2]
  def change
    rename_column :issues, :group_id, :campaign_id
  end
end
