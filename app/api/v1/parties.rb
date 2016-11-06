module V1
  class Parties < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :parties do
      desc '내가 메이커가 아닌 가입만한 빠띠 목록을 반환합니다'
      oauth2
      get :joined_only do
        present :parties, resource_owner.only_watched_issues
      end

      desc '내가 메이커인 빠띠 목록을 반환합니다'
      oauth2
      get :making do
        present :parties, resource_owner.making_issues
      end

      desc '내가 모든 빠띠 목록을 반환합니다'
      oauth2
      get do
        present :parties, Issue.all.limit(20)
      end

      desc '해당 빠띠의 모든 글을 반환합니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
      end
      get ':slug/posts' do
        @issue = Issue.find_by(slug: params[:slug])
        base_posts = @issue.posts
        @last_post = base_posts.newest(field: :last_touched_at)

        previous_last_post = Post.with_deleted.find_by(id: params[:last_id])

        watched_posts = base_posts.order(last_touched_at: :desc)
        @posts = base_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (base_posts.any? and base_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, @posts, current_user: resource_owner, type: :full
      end
    end
  end
end
