module V1
  class Posts < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    helpers do
      def fetch_posts_page last_id
        watched_posts = resource_owner.watched_posts.order(last_stroked_at: :desc)
        previous_last_post = Post.with_deleted.find_by(id: last_id)

        @posts = watched_posts.limit(20)
        @posts = @posts.previous_of_post(previous_last_post) if previous_last_post.present?

        current_last_post = @posts.last
        @has_more_item = (watched_posts.any? and watched_posts.previous_of_post(current_last_post).any?)
      end
    end

    namespace :posts do
      desc '한 사용자가 쓴 글을 반환합니다.'
      oauth2
      params do
        requires :user_id, type: Integer, desc: '사용자 번호'
        optional :last_id, type: Integer, desc: '이전 마지막 게시글 번호'
      end
      get 'by_user' do
        @user = User.find_by(id: params[:user_id])
        base_posts = @user.posts

        previous_last_post = Post.with_deleted.find_by(id: params[:last_id])
        user_posts = base_posts.order(last_stroked_at: :desc)
        @posts = user_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (base_posts.any? and user_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, @posts, base_options.merge(type: :full)
      end

      desc '내홈의 게시글을 페이지별로 가져옵니다'
      oauth2
      params do
        optional :last_id, type: Integer, desc: '이전에 보고 있던 게시글 중에 마지막 게시글 번호'
      end
      get :dashboard do
        last_id = params[:last_id]
        loop do
          fetch_posts_page last_id
          @result_posts = Post.reject_blinded_or_blocked(@posts, resource_owner)
          last_id = @posts.last.try(:id)
          break if !@has_more_item or @result_posts.any?
        end

        present :last_stroked_at, resource_owner.member_issues.maximum(:last_stroked_at)
        present :has_more_item, @has_more_item
        present :items, @result_posts, base_options.merge(type: :full)
      end

      desc '새로운 글이 있는지 확인합니다'
      oauth2
      params do
        requires :last_stroked_at, type: String, desc: '기준 시점'
      end
      get :has_updated do
        if params[:last_stroked_at].present?
          last_stroked_at = Time.parse params[:last_stroked_at]
        else
          last_stroked_at = nil
        end
        logger.debug(last_stroked_at)
        new_posts = resource_owner.watched_posts
        new_posts = new_posts.where.not(last_stroked_user: resource_owner)
        new_posts = new_posts.next_of_time(last_stroked_at) if last_stroked_at.present?
        logger.debug(new_posts.any?.inspect)
        present :has_updated, new_posts.any?
        present :last_stroked_at, new_posts.maximum(:last_stroked_at)
      end

      desc '특정 댓글의 게시글정보를 반환합니다'
      oauth2
      params do
        requires :comment_id, type: Integer, desc: '댓글 번호'
      end
      get 'by_sticky_comment' do
        @comment = Comment.find_by(id: params[:comment_id])
        error!(:not_found, 410) and return if @comment.blank?

        @post = @comment.post
        error!(:forbidden, 403) and return if @post.private_blocked?(resource_owner)

        present @post, base_options.merge(type: :full, sticky_comment: @comment)
      end

      desc '특정 글에 대한 정보를 반환합니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '글 번호'
      end
      get ':id' do
        @post = Post.find_by(id: params[:id])
        error!(:not_found, 410) and return if @post.blank?
        error!(:forbidden, 403) and return if @post.private_blocked?(resource_owner)

        present @post, base_options.merge(type: :full)
      end

      desc '파일을 다운로드합니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '글 번호'
        requires :file_source_id, type: Integer, desc: '파일번호'
      end
      get ':id/download_file/:file_source_id' do
        @post = Post.find_by(id: params[:id])
        error!(:not_found, 410) and return if @post.blank?
        error!(:forbidden, 403) and return if @post.private_blocked?(current_user)

        @file_source = @post.file_sources.find_by!(id: params[:file_source_id])

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

      desc '게시글을 작성합니다'
      oauth2
      params do
        requires :post, type: Hash do
          requires :body, type: String
          requires :parti_id, type: Integer
          requires :is_html_body, type: String
          optional :file_sources_attributes, type: Array do
            requires :attachment, type: Rack::Multipart::UploadedFile
          end
        end
      end
      post do
        permitted_params = permitted(params, :post)
        permitted_params[:issue_id] = permitted_params.delete :parti_id

        @post = Post.new permitted_params
        error!(:forbidden, 403) and return if @post.issue.blank? or @post.issue.private_blocked?(current_user) or !@post.issue.postable?(current_user)
        error!('bad request', 500) and return if permitted_params[:body].blank?

        service = PostCreateService.new(post: @post, current_user: current_user)

        if service.call
          present @post, base_options.merge(type: :full)
        else
          logger.error("fail to save post")
          logger.error(@post.errors.inspect)
          error!('private issue', 500)
        end
      end

      desc '한 게시글의 댓글을 반환합니다.'
      oauth2
      params do
        requires :id, type: Integer, desc: '게시글 번호'
        optional :last_comment_id, type: Integer, desc: '이전 마지막 댓글 번호'
      end
      get ':id/comments' do
        @post = Post.find_by(id: params[:id])
        error!(:not_found, 410) and return if @post.blank?
        error!(:forbidden, 403) and return if @post.issue.blank? or @post.private_blocked?(current_user)
        base_comments = @post.comments.recent

        previous_last_comment = Comment.with_deleted.find_by(id: params[:last_comment_id])
        @comments = base_comments.limit(25).previous_of(previous_last_comment.try(:id))

        current_last_comment = @comments.last

        @has_more_item = (base_comments.any? and base_comments.previous_of(current_last_comment.try(:id)).any?)

        present :has_more_item, @has_more_item
        present :items, @comments.reverse, base_options.merge(type: :full)
      end
    end
  end
end
