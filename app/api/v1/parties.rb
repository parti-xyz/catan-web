module V1
  class Parties < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    helpers do
      def parties_joined_only
        resource_owner.only_watched_issues.sort{ |a, b| a.compare_title(b) }
      end

      def parties_making
        resource_owner.making_issues.sort{ |a, b| a.compare_title(b) }
      end
    end

    namespace :parties do
      desc '내가 메이커가 아닌 가입만한 빠띠 목록을 반환합니다'
      oauth2
      get :joined_only do
        present :parties, parties_joined_only
      end

      desc '내가 메이커인 빠띠 목록을 반환합니다'
      oauth2
      get :making do
        present :parties, parties_making
      end

      desc '모든 빠띠 목록을 반환합니다'
      oauth2
      params do
        optional :sort, type: Symbol, values: [:hottest, :recent], default: :hottest, desc: '정렬 조건'
      end
      get do
        present :parties, Issue.all.send(params[:sort]).limit(20)
      end

      desc '앱에서 기본으로 보여질 빠띠를 반환합니다.'
      oauth2
      get :first do
        if parties_making.any?
          @first = parties_making.first
        elsif parties_joined_only.any?
          @first = parties_joined_only.first
        else
          @first = Issue.hottest.first
        end

        present :parti, @first
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
