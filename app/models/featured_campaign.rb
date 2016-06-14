class FeaturedCampaign < ActiveRecord::Base
  mount_uploader :image, ImageUploader
  mount_uploader :mobile_image, ImageUploader
end
