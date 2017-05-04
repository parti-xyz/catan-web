class LinkSource < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :url, :title, :body, :site_name, :page_type
    expose :image_url, if: lambda { |instance, options| instance.has_image? } do |instance|
      instance.image.md.url
    end
    expose :is_video do |instance|
      instance.is_video?
    end
    with_options(if: lambda { |instance, options| instance.is_video? }) do |instance|
      expose :video_embeded_code do |instance|
        instance.video.embed_code
      end
      expose :video_app_url
    end
  end
  extend Enumerize

  URL_FORMAT = /\A(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,20}(:[0-9]{1,5})?(\/.*)?\z/ix

  has_many :posts, dependent: :nullify

  validates :url, uniqueness: {case_sensitive: true}, format: {with: LinkSource::URL_FORMAT, on: [:create, :update] }
  validates :crawling_status, presence: true
  enumerize :crawling_status, in: [:not_yet, :completed], predicates: true, scope: true
  ## uploaders
  # mount
  mount_uploader :image, ImageUploader

  before_validation :strip_whitespace
  after_initialize :set_crawling_status

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

  def unify
    previous_link_source = LinkSource.find_by(url: self.url)
    previous_link_source.present? ? previous_link_source : self
  end

  def is_video?
    VideoInfo.usable?(self.url) and video.try(:available?)
  end

  def video
    @video ||= VideoInfo.new(self.url)
  end

  def video_app_url
    return if video.blank?
    case video.provider
    when 'YouTube'
      "vnd.youtube:#{video.video_id}"
    when ''
      "vimeo://app.vimeo.com/videos/#{video.video_id}"
    end
  end

  def title_or_url
    title || url
  end

  def self.require_attrbutes
    [:url]
  end

  def has_image?
    self["image"].present?
  end

  private

  def set_crawling_status
    self.crawling_status = 'not_yet' if self.new_record?
  end

  def strip_whitespace
    self.url = self.url.gsub(/\s+/, "") unless self.url.nil?
  end

end
