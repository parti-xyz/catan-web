module V1
  class Posts < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

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
        user_posts = base_posts.order(last_touched_at: :desc)
        @posts = user_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (base_posts.any? and user_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, @posts, base_options.merge(type: :full)
      end

      desc '내홈 글을 가져옵니다'
      oauth2
      get :dashboard do
        watched_posts = resource_owner.watched_posts

        previous_last_post = Post.with_deleted.find_by(id: params[:last_id])

        watched_posts = watched_posts.order(last_touched_at: :desc)
        @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (watched_posts.any? and watched_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, @posts, current_user: resource_owner, type: :full
      end

      desc '최신 글 갯수를 가져옵니다'
      oauth2
      params do
        requires :last_touched_at, type: String, desc: '기준 시점'
      end
      get :new_count do
        last_touched_at = Time.parse params[:last_touched_at]
        logger.debug(last_touched_at)
        count = resource_owner.watched_posts.order(last_touched_at: :desc).next_of_last_touched_at(last_touched_at).count
        present :posts_count, count
      end

      desc '특정 글에 대한 정보를 반환합니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '글 번호'
      end
      get ':id' do
        @post = Post.find_by!(id: params[:id])
        present :post, @post
      end

      desc '게시글을 작성합니다'
      oauth2
      params do
        requires :post, type: Hash do
          requires :body, type: String
          requires :parti_id, type: Integer
          optional :reference, type: Hash do
            optional :attachment, type: String
            optional :poll, type: String
            optional :link, type: String
          end
        end
      end
      post do
        permitted_params = permitted(params, :post)
        permitted_params[:issue_id] = permitted_params.delete :parti_id
        reference = permitted_params.delete :reference
        @post = Post.new permitted_params
        @post.user = resource_owner
        @post.section = @post.issue.initial_section
        @post.format_linkable_body
        if reference.present?
          if reference[:attachment].present?
            @post.reference = FileSource.new(attachment: reference[:attachment], name: 'file-#{DateTime.now.to_i}')
          elsif reference[:link].present?
            @post.reference = LinkSource.new(url: reference[:link])
          elsif reference[:poll].present?
            @post.poll = Poll.new(title: reference[:poll])
          end
        end
        @post.save!

        if @post.link_source?
          CrawlingJob.perform_async(@post.reference.id)
        end
        present :post, @post, base_options.merge(type: :full)
      end
    end
  end
end
