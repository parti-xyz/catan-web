class DropFeaturedCampaigns < ActiveRecord::Migration
  def change
  	drop_table :featured_campaigns
  end
end
