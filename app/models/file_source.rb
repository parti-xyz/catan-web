class FileSource < ActiveRecord::Base
  ## uploaders
  # mount
  mount_uploader :attachment, FileUploader

  before_save :update_type

  validates :name, presence: true
  validates :attachment, presence: true

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

  private

  def update_type
    if attachment.present? && attachment_changed?
      self.file_type = attachment.file.content_type
      self.file_size = attachment.file.size
    end
  end


end
