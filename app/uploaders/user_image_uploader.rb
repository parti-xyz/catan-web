# encoding: utf-8

class UserImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def self.env_storage
    if Rails.env.production?
      :aws
    else
      :file
    end
  end

  storage env_storage

  def initialize(*)
    super

    if Rails.env.production?
      self.aws_credentials = {
        access_key_id: ENV["S3_ACCESS_KEY"],
        secret_access_key: ENV["S3_SECRET_KEY"],
        region: ENV["S3_REGION"]
      }
      self.aws_bucket = ENV["S3_BUCKET"]
      self.aws_acl = 'public-read'
      self.aws_attributes = {
        expires: 1.week.from_now.httpdate,
        cache_control: 'max-age=604800'
      }
    end
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if model.blank?
      return "uploads/user_image/#{rand(1..100)}"
    end

    "uploads/user/#{model.id / 1000}"
  end

  def content_type_whitelist
    /image\//
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url(*args)
    Identicon.data_url_for model&.try(:nickname) || 'default', 128, [240, 240, 240]
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

  def url(*args)
    super_result = super(args)

    if Rails.env.production?
      return super_result
    elsif self.model&.read_attribute(self.mounted_as.to_sym).blank?
      super_result
    else
      if self.file.try(:exists?) or ENV["S3_BUCKET"].blank?
        ActionController::Base.helpers.asset_url(super_result)
      else
        "https://#{ENV["S3_BUCKET"]}.s3.amazonaws.com#{super_result}"
      end
    end
  end

  def fix_exif_rotation
    manipulate! do |img|
      img.tap(&:auto_orient)
    end
  end

  process :fix_exif_rotation

  protected

  def secure_token(length=16)
    if model.blank?
      return SecureRandom.hex(length/2)
    end
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  end
end
