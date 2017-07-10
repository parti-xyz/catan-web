# encoding: utf-8
class Redactor2RailsFileUploader < CarrierWave::Uploader::Base
  include Redactor2Rails::Backend::CarrierWave

  # storage :fog
  if Rails.env.production?
    storage :fog
  else
    storage :file
  end

  def store_dir
    "uploads/redactor2_assets/files/#{model.id}"
  end

  def extension_white_list
    Redactor2Rails.files_file_types
  end

  def filename
     "#{secure_token(10)}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token(length=16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  end
end
