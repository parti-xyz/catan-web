module V1
  class Parties < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    helpers do
      def parties_joined(someone)
        someone.member_issues
      end
    end

    namespace :parties do

      desc '한 사용자가 가입한 빠띠 목록을 반환합니다'
      oauth2
      params do
        requires :user_id, type: Integer, desc: '사용자 번호'
        optional :sort, type: Symbol, values: [:hottest, :recent], default: :hottest, desc: '정렬 조건'
        optional :limit, type: Integer, default: 50
      end
      get :joined do
        user = User.find_by(id: params[:user_id])
        present :parties, parties_joined(user).send(params[:sort]).limit(params[:limit]), base_options
      end

      desc '모든 빠띠 목록을 반환합니다'
      oauth2
      params do
        optional :sort, type: Symbol, values: [:hottest, :recent], default: :hottest, desc: '정렬 조건'
        optional :limit, type: Integer, default: 50
      end
      get do
        present :parties, Issue.all.send(params[:sort]).limit(params[:limit]), base_options
      end

      desc '태그 달린 빠띠들을 반환합니다'
      oauth2
      params do
        requires :tags, type: Array[String]
      end
      get :tagged do
        present :parties, Issue.hottest.tagged_with(params[:tags], any: true), base_options
      end

      desc '특정 빠띠에 대한 정보를 반환합니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
        optional :group_slug, type: String, desc: '빠띠의 그룹 slug'
      end
      get ':slug' do
        @issue = Issue.find_by!(slug: params[:slug], group_slug: params[:group_slug])
        present :parti, @issue
      end

      desc '해당 빠띠의 모든 글을 반환합니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
        optional :group_slug, type: String, desc: '빠띠의 그룹 slug'
        optional :last_id, type: Integer, desc: '이전 마지막 게시글 번호'
      end
      get ':slug/posts' do
        @issue = Issue.find_by(slug: params[:slug], group_slug: params[:group_slug])
        base_posts = @issue.posts
        @last_post = base_posts.newest(field: :last_touched_at)

        previous_last_post = Post.with_deleted.find_by(id: params[:last_id])
        watched_posts = base_posts.order(last_touched_at: :desc)
        @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (base_posts.any? and watched_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, Post.reject_blinds(@posts, resource_owner), base_options.merge(type: :full)
      end

      desc '해당 빠띠의 멤버를 조회합니다'
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
        optional :group_slug, type: String, desc: '빠띠의 그룹 slug'
      end
      get ':slug/members' do
        issue = Issue.find_by!(slug: params[:slug], group_slug: params[:group_slug])
        present :members, issue.members, base_options
      end

      desc '가입했습니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
        optional :group_slug, type: String, desc: '빠띠의 그룹 slug'
      end
      post ':slug/members' do
        @issue = Issue.find_by(slug: params[:slug], group_slug: params[:group_slug])

        return if @issue.member?(resource_owner)
        @issue.members.build(user: resource_owner)
        @issue.save!
      end

      desc '탈퇴했습니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
        optional :group_slug, type: String, desc: '빠띠의 그룹 slug'
      end
      delete ':slug/members' do
        @issue = Issue.find_by(slug: params[:slug], group_slug: params[:group_slug])

        return if !@issue.member?(resource_owner)
        return if @issue.made_by? resource_owner
        ActiveRecord::Base.transaction do
          @issue.members.find_by(user: resource_owner).try(:destroy!)
        end
      end
    end
  end
end
