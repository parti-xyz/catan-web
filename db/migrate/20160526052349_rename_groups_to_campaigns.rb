class RenameGroupsToCampaigns < ActiveRecord::Migration[4.2]
  def change
    rename_table :groups, :campaigns
  end
end
