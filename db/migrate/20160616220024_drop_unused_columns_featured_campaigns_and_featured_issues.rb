class DropUnusedColumnsFeaturedCampaignsAndFeaturedIssues < ActiveRecord::Migration[4.2]
  def change
    remove_column :featured_campaigns, :title, :string
    remove_column :featured_campaigns, :body, :text
    remove_column :featured_issues, :body, :text
  end
end
