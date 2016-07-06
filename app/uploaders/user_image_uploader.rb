# encoding: utf-8

class UserImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  if Rails.env.production? or Rails.env.staging?
    storage :fog
  else
    storage :file
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/user/#{model.id / 1000}"
  end

  def content_type_whitelist
    /image\//
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    Identicon.data_url_for model.try(:nickname) || 'default', 128, [240, 240, 240]
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  version :xs  do
    process resize_to_fit: [80, nil]
  end

  version :sm do
    process resize_to_fit: [200, nil ]
  end

  version :md do
    process resize_to_fit: [400, nil]
  end

  version :lg do
    process resize_to_fit: [700, nil]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{secure_token(10)}.#{file.extension}" if original_filename.present?
  end

  def url
    (!Rails.env.development? or self.file.exists?) ? super : "https://catan-file.s3.amazonaws.com#{super}"
  end

  protected

  def secure_token(length=16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  end
end
