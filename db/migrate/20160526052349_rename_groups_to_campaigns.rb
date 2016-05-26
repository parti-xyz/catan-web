class RenameGroupsToCampaigns < ActiveRecord::Migration
  def change
    rename_table :groups, :campaigns
  end
end
