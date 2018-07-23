class CreateFeaturedCampaigns < ActiveRecord::Migration[4.2]
  def change
    create_table :featured_campaigns do |t|
      t.string :title
      t.string :url
      t.text :body
      t.string :image
      t.string :mobile_image
      t.timestamps null: false
    end
  end
end
