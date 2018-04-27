class FileSource < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    include ActionView::Helpers::NumberHelper
    expose :id, :attachment_url, :name, :file_type, :file_size, :image_ratio
    expose :attachment_sm_url do |instance|
      instance.sm_url
    end
    expose :attachment_md_url do |instance|
      instance.md_url
    end
    expose :attachment_lg_url do |instance|
      instance.lg_url
    end
    expose :human_file_size do |instance|
      number_to_human_size(instance.file_size)
    end
  end

  belongs_to :file_sourceable, counter_cache: true, polymorphic: true

  ## uploaders
  # mount
  mount_base64_uploader :deprecated_attachment, DeprecatedFileUploader, file_name: -> { 'userpic' }
  mount_base64_uploader :attachment, PrivateFileUploader, file_name: -> { 'userpic' }

  before_save :update_type

  validates :name, presence: true
  validates :attachment, presence: true, on: :create
  validates :attachment, file_size: { less_than_or_equal_to: 10.megabytes, greater_than: 0.byte }

  scope :sort_by_seq_no, -> { order(:seq_no).order(:id) }
  scope :only_image, -> { where("file_type like 'image/%'") }
  scope :only_doc, -> { where("file_type not like 'image/%'") }

  def unify
    self
  end

  def title
    name
  end

  def image?
    attachment.content_type.try(:start_with?, 'image')
  end

  def doc?
    !attachment.content_type.try(:start_with?, 'image')
  end

  def url
    image? ? attachment.url : Rails.application.routes.url_helpers.download_file_source_path(self)
  end

  def md_url
    image? ? attachment.md.url : Rails.application.routes.url_helpers.download_file_source_path(self)
  end

  def lg_url
    image? ? attachment.lg.url : Rails.application.routes.url_helpers.download_file_source_path(self)
  end

  def sm_url
    image? ? attachment.sm.url : Rails.application.routes.url_helpers.download_file_source_path(self)
  end

  def valid_name
    self.name.gsub(/\\+/, "%20")
  end

  def image_ratio
    return 0.8 if image_width == 0 or image_height == 0
    image_width / image_height.to_f
  end

  IMAGE_WIDTH_MAX_LG = 700
  def image_width_lg
    return 0 unless image?
    return IMAGE_WIDTH_MAX_LG
  end

  def image_height_lg
    return 0 unless image?
    return 0 if image_width_lg == 0 or image_height == 0 or image_width == 0
    (image_width_lg * image_height / image_width.to_f).ceil
  end

  def self.require_attrbutes
    [:id, :seq_no, :attachment, :attachemnt_cache, :_destroy]
  end

  private

  def update_type
    if attachment.present? && attachment_changed?
      self.file_type = attachment.file.content_type
      self.file_size = attachment.file.size
    end
  end
end
