class AddTitleAndBodyToFeaturedCampaigns < ActiveRecord::Migration[4.2]
  def change
    add_column :featured_campaigns, :title, :string
    add_column :featured_campaigns, :body, :text
  end
end
