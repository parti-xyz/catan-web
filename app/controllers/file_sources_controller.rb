class FileSourcesController < ApplicationController
  def download
    @file_source = FileSource.find params[:id]
    if @file_source.attachment.file.respond_to?(:url)
      # s3
      data = open @file_source.attachment.url
      send_data data.read, filename: @file_source.name, type: @file_source.file_type, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    else
      # local storage
      send_file(@file_source.attachment.path, type: @file_source.file_type, disposition: 'attachment')
    end
  end
end
