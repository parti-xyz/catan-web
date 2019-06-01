module V1
  class Posts < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :posts do
      # 하위호환을 위해 남겨 둡니다
      desc '파일을 다운로드합니다'
      params do
        requires :id, type: Integer, desc: '글 번호'
        requires :file_source_id, type: Integer, desc: '파일번호'
      end
      get ':id/download_file/:file_source_id' do
        @file_source = FileSource.find_by!(id: params[:file_source_id])

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

      desc '채널별 게시물 목록으로 반환합니다'
      oauth2
      params do
        #optional :limit, type: Integer, desc: '최근 게시물 갯수', default: 10
      end
      get do
        issue = Issue.find params[:channel_id]
        error!(:forbidden, 403) and return if issue.private_blocked?(resource_owner)

        posts = issue.posts.order(last_stroked_at: :desc)

        previous_last_post = Post.with_deleted.find_by(id: params[:last_post_id])
        posts = posts.limit(20).previous_of_post(previous_last_post)
        current_last_post = posts.last
        is_last_page = (posts.empty? or posts.previous_of_post(current_last_post).empty?)

        present_authed :posts, posts
        present_authed :isLastPage, is_last_page
      end
    end
  end
end
