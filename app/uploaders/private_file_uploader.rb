# encoding: utf-8

class PrivateFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def self.env_storage
    if Rails.env.production?
      :fog
    else
     :file
    end
  end

  storage env_storage

  def initialize(*)
    super

    if Rails.env.production?
      self.fog_credentials = {
        provider:              'AWS',
        aws_access_key_id:     ENV["PRIVATE_S3_ACCESS_KEY"],
        aws_secret_access_key: ENV["PRIVATE_S3_SECRET_KEY"],
        region:                ENV["PRIVATE_S3_REGION"]
      }
      self.fog_directory = ENV["PRIVATE_S3_BUCKET"]
      self.fog_public = false
    else
      @production_storage = Fog::Storage.new(
        provider:              'AWS',
        aws_access_key_id:     ENV["PRIVATE_S3_ACCESS_KEY"],
        aws_secret_access_key: ENV["PRIVATE_S3_SECRET_KEY"],
        region:                ENV["PRIVATE_S3_REGION"])
    end
  end

  def store_dir
    return '' if Rails.env.test?
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end
  # def default_url
  #   ActionController::Base.helpers.asset_path("default_#{model.class.to_s.underscore}_#{mounted_as}.png")
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end
  version :xs, if: :image?  do
    process resize_to_fit: [80, nil]
  end

  version :sm, if: :image? do
    process resize_to_fit: [200, nil ]
  end

  version :md, if: :image? do
    process resize_to_fit: [400, nil]
  end

  version :lg, if: :image? do
    process resize_to_fit: [700, nil]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  def filename
     "#{secure_token(10)}.#{file.extension}" if original_filename.present?
  end

  def url
    if Rails.env.test?
      return super
    end

    if self.model.read_attribute(self.mounted_as.to_sym).blank?
      super
    elsif Rails.env.production?
      super
    else
      super_result = super
      if self.file.try(:exists?) or @production_storage.blank?
        ActionController::Base.helpers.asset_url(super_result)
      else
        if self.fog_authenticated_url_expiration > 60
          Rails.cache.fetch(super_result, expires_in: ((self.fog_authenticated_url_expiration || 600) - 60)) do
            production_s3_url super_result
          end
        else
          production_s3_url super_result
        end
      end
    end
  end

  def production_s3_url super_result
    @production_s3_bucket ||= @production_storage.directories.new(key: ENV["PRIVATE_S3_BUCKET"])
    @production_s3_bucket.files.new(key: super_result[1..-1]).try(:url, ::Fog::Time.now.to_i + self.fog_authenticated_url_expiration)
  end

  def fix_exif_rotation
    if image?(self.file)
      manipulate! do |img|
        img.tap(&:auto_orient)
      end
    end
  end

  process :fix_exif_rotation

  before :cache, :save_original_filename
  def save_original_filename(file)
    model.name ||= file.original_filename.unicode_normalize if file.respond_to?(:original_filename)
  end

  protected

  def image?(new_file)
    new_file.content_type.try(:start_with?, 'image')
  end

  def secure_token(length=16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  end
end
