class LinkSource < ActiveRecord::Base
  extend Enumerize

  has_many :articles

  validates :url, uniqueness: {case_sensitive: true}
  validates :crawling_status, presence: true
  enumerize :crawling_status, in: [:not_yet, :completed], predicates: true, scope: true
  ## uploaders
  # mount
  mount_uploader :image, ImageUploader

  def set_crawling_data(data)
    self.metadata = data.metadata.to_json || self.metadata
    self.title = data.title || self.title
    self.image = (data.image_io if data.image_io) || self.image
    self.image_width = (data.image_width if data.image_io) || self.image_width
    self.image_height = (data.image_height if data.image_io) || self.image_height
    self.page_type = data.type || self.page_type
    self.body = data.description || self.body
    self.site_name = data.site_name || self.site_name
    self.crawling_status = :completed
    self.crawled_at = DateTime.now
  end
end
