class RemoveCampaignOfIssues < ActiveRecord::Migration
  def change
    remove_column :issues, :group_id
  end
end
