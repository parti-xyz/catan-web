class LinkSource < ActiveRecord::Base
  extend Enumerize

  has_many :articles

  validates :url, uniqueness: {case_sensitive: true}
  enumerize :crawling_status, in: [:not_yet, :completed], predicates: true, scope: true

  ## uploaders
  # mount
  mount_uploader :image, ImageUploader

  def set_crawling_data(data)
    self.metadata = data.metadata.to_json || self.metadata
    self.title = data.title || self.title
    self.remote_image_url = (data.images[0] if data.images.try(:any?)) || self.image
    self.page_type = data.type || self.page_type
    self.body = data.description || self.body
    self.crawling_status = :completed
    self.crawled_at = DateTime.now
  end
end
