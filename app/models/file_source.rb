class FileSource < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :attachment_url, :name, :file_type, :file_size
    expose :attachment_filename do |model|
      model.attachment.file.filename
    end
  end
  ## uploaders
  # mount
  mount_uploader :attachment, FileUploader

  before_save :update_type

  validates :name, presence: true
  validates :attachment, presence: true
  validates :attachment, file_size: { less_than: 10.megabytes }

  def unify
    self
  end

  def title
    name
  end

  def image?
    attachment.content_type.start_with? 'image'
  end

  def url
    image? ? attachment.url : Rails.application.routes.url_helpers.download_file_source_path(self)
  end

  def valid_name
    self.name.gsub(/\\+/, "%20")
  end

  def self.require_attrbutes
    [:attachment]
  end

  private

  def update_type
    if attachment.present? && attachment_changed?
      self.file_type = attachment.file.content_type
      self.file_size = attachment.file.size
    end
  end


end
