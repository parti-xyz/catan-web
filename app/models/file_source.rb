class FileSource < ActiveRecord::Base
  ## uploaders
  # mount
  mount_uploader :attachment, FileUploader

  before_save :update_type

  def unify
    self
  end

  def image?
    attachment.content_type.start_with? 'image'
  end

  private

  def update_type
    if attachment.present? && attachment_changed?
      self.file_type = attachment.file.content_type
      self.file_size = attachment.file.size
    end
  end


end
