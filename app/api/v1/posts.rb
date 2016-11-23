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
        @last_post = base_posts.newest

        previous_last_post = Post.with_deleted.find_by(id: params[:last_id])
        user_posts = base_posts.order(last_touched_at: :desc)
        @posts = user_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (base_posts.any? and user_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, @posts, base_options.merge(type: :full)
      end

      desc '내홈의 글을 가져옵니다'
      oauth2
      get :dashboard do
        watched_posts = resource_owner.watched_posts
        @last_post = watched_posts.newest(field: :last_touched_at)

        previous_last_post = Post.with_deleted.find_by(id: params[:last_id])

        watched_posts = watched_posts.order(last_touched_at: :desc)
        @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (watched_posts.any? and watched_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, @posts, current_user: resource_owner, type: :full
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
          requires :issue_id, type: Integer
        end
      end
      post do
        @talk = Talk.new permitted(params, :post)
        @talk.user = resource_owner
        @talk.section = @talk.issue.initial_section
        @talk.body = view_context.autolink_format(@talk.body)
        @talk.save!
        present :post, @talk.acting_as, base_options.merge(type: :full)
      end
    end
  end
end
