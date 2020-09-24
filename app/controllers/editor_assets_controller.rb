class EditorAssetsController < ApplicationController
  before_action :authenticate_user!

  def create
    # Take upload from params[:file] and store it somehow...
    # Optionally also accept params[:hint] and consume if needed
    uploader = ImageUploader.new
    file = params[:file]
    if file.size.to_f > 10.megabyte
      error(t("activerecord.errors.models.file_source.attributes.attachment.file_size_is_less_than_or_equal_to")) and return
    elsif file.size.to_f <= 0
      error(t("activerecord.errors.models.file_source.attributes.attachment.file_size_is_greater_than")) and return
    end

    uploader.store!(file)

    render json: {
      image: {
        url: view_context.image_url(uploader.lg.url)
      }
    }, content_type: "text/html"
  end

  private

  def error(message)
    render json: {
      error: {
        message: message
      }
    }, content_type: "text/html"
  end
end
