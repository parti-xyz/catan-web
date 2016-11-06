module V1
  class Dashboard < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :dashboard do
      desc '내홈의 글을 가져옵니다'
      oauth2
      get :posts do
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
    end
  end
end
