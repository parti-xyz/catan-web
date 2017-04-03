class FileSource < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :attachment_url, :name, :file_type, :file_size
    expose :attachment_filename do |instance|
      instance.attachment.file.filename
    end
  end

  belongs_to :post, counter_cache: true

  ## uploaders
  # mount
  mount_base64_uploader :attachment, FileUploader, file_name: 'userpic'

  before_save :update_type

  validates :name, presence: true
  validates :attachment, presence: true
  validates :attachment, file_size: { less_than: 10.megabytes }

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

  def valid_name
    self.name.gsub(/\\+/, "%20")
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
