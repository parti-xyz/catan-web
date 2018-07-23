class CreateCampaignedIssues < ActiveRecord::Migration[4.2]
  def change
    create_table :campaigned_issues do |t|
      t.references :campaign, null: false, index: true
      t.references :issue, null: false, index: true
      t.timestamps null: false
    end

    add_index :campaigned_issues, [:campaign_id, :issue_id], unique: true
  end
end
