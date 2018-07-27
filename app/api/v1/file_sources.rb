module V1
  class FileSources < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :file_sources do
      desc '파일을 다운로드합니다'
      params do
        requires :id, type: Integer, desc: '파일번호'
      end
      get 'download_file/:id' do
        @file_source = FileSource.find_by!(id: params[:id])

        error!(:not_found, 410) and return if @file_source.file_sourceable.blank?
        error!(:forbidden, 403) and return if @file_source.file_sourceable.private_blocked?(current_user)


        content_type @file_source.file_type || MIME::Types.type_for(@file_source.read_attribute(:attachment))[0].to_s
        env['api.format'] = :binary
        header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(@file_source.name)}"
        if @file_source.attachment.file.respond_to?(:url)
          # s3
          data = open @file_source.attachment.url
          data.read
        else
          # local storage
          File.open(@file_source.attachment.path).read
        end
      end
    end
  end
end
