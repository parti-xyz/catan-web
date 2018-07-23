class DropFeaturedCampaigns < ActiveRecord::Migration[4.2]
  def change
  	drop_table :featured_campaigns
  end
end
