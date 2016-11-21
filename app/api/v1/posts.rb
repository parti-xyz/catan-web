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

      desc '특정 글에 대한 정보를 반환합니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '글 번호'
      end
      get ':id' do
        @post = Post.find_by!(id: params[:id])
        present :post, @post
      end
    end
  end
end
