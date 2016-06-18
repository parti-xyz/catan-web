class AddTitleAndBodyToFeaturedCampaigns < ActiveRecord::Migration
  def change
    add_column :featured_campaigns, :title, :string
    add_column :featured_campaigns, :body, :text
  end
end
