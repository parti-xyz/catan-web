class FileSourcesController < ApplicationController
  def download
    @file_source = FileSource.find params[:id]
    if @file_source.attachment.file.respond_to?(:url)
      # s3
      data = open @file_source.attachment.url
      send_data data.read, filename: encoded_file_name(@file_source), type: @file_source.file_type, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    else
      # local storage
      send_file(@file_source.attachment.path, filename: encoded_file_name(@file_source), type: @file_source.file_type, disposition: 'attachment')
    end
  end

  private

  def encoded_file_name file_source
    filename = file_source.valid_name
    if browser.ie?
      filename = URI::encode(filename)
    elsif ENV['FILENAME_ENCODING'].present?
      filename = filename.encode('UTF-8', ENV['FILENAME_ENCODING'], invalid: :replace, undef: :replace, replace: '?')
    end
    filename
  end
end
