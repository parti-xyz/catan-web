module V1
  class Parties < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    helpers do
      def parties_joined(someone)
        someone.member_issues
      end

      def fetch_posts_page issue, last_id
        base_posts = issue.posts.order(last_stroked_at: :desc)
        previous_last_post = Post.with_deleted.find_by(id: last_id)

        @posts = base_posts.limit(40)
        @posts = @posts.previous_of_post(previous_last_post) if previous_last_post.present?

        current_last_post = @posts.last
        @has_more_item = (base_posts.any? and base_posts.previous_of_post(current_last_post).any?)
      end
    end

    namespace :parties do

      desc '현재 로그인한 사용자가 가입한 빠띠 목록을 반환합니다'
      oauth2
      params do
        optional :sort, type: Symbol, values: [:hottest, :recent], default: :hottest, desc: '정렬 조건'
        optional :limit, type: Integer, default: 50
      end
      get :my_joined do
        present parties_joined(current_user).send(params[:sort]).limit(params[:limit]), base_options.merge(target_user: current_user)
      end

      desc '한 사용자가 가입한 빠띠 목록을 반환합니다'
      oauth2
      params do
        requires :user_id, type: Integer, desc: '사용자 번호'
        optional :sort, type: Symbol, values: [:hottest, :recent], default: :hottest, desc: '정렬 조건'
        optional :limit, type: Integer, default: 50
      end
      get :joined do
        user = User.find_by(id: params[:user_id])
        present parties_joined(user).send(params[:sort]).limit(params[:limit]), base_options.merge(target_user: user)
      end

      desc '모든 빠띠 목록을 반환합니다'
      oauth2
      params do
        optional :sort, type: Symbol, values: [:hottest, :recent], default: :hottest, desc: '정렬 조건'
        optional :limit, type: Integer, default: 50
      end
      get do
        present Issue.alive.send(params[:sort]).limit(params[:limit]), base_options
      end

      desc '태그 달린 빠띠들을 반환합니다'
      oauth2
      params do
        requires :tags, type: Array[String]
      end
      get :tagged do
        present Issue.alive.hottest.tagged_with(params[:tags], any: true), base_options
      end

      desc '특정 빠띠에 대한 정보를 반환합니다'
      oauth2
      params do
        requires :id, type: String, desc: '빠띠의 id'
      end
      get ':id' do
        @issue = Issue.find_by!(id: params[:id])
        present @issue, base_options.merge(target_user: current_user)
      end

      desc '빠띠 게시글을 페이지별로 가져옵니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '빠띠의 ID'
        optional :last_id, type: Integer, desc: '이전에 보고 있던 게시글 중에 마지막 게시글 번호'
      end
      get ':id/posts' do
        last_id = params[:last_id]
        @issue = Issue.find_by(id: params[:id])
        error!(:not_found, 404) and return if @issue.blank?
        error!(:forbidden, 403) and return if @issue.private_blocked?(resource_owner)

        loop do
          fetch_posts_page @issue, last_id
          @result_posts = Post.reject_blinded_or_blocked(@posts, resource_owner)
          last_id = @posts.last.try(:id)
          break if !@has_more_item or @result_posts.any?
        end

        present :has_more_item, @has_more_item
        present :items, @result_posts, base_options.merge(type: :full)
      end

      desc '해당 빠띠의 멤버회원을 반환합니다'
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
        optional :group_slug, type: String, desc: '빠띠의 그룹 slug'
        optional :last_id, type: Integer, desc: '이전 마지막 회원 번호'
      end
      get ':slug/members' do
        issue = Issue.find_by!(slug: params[:slug], group_slug: params[:group_slug])
        members_base = issue.members.recent

        @members = members_base.limit(25)
        @members = @members.where('id < ?', params[:last_id]) if params[:last_id].present?
        current_last = @members.last
        @has_more_item = (members_base.any? and members_base.where('id < ?', current_last.try(:id)).any?)

        present :has_more_item, @has_more_item
        present :items, @members
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
        return if @issue.organized_by? resource_owner
        ActiveRecord::Base.transaction do
          @issue.members.find_by(user: resource_owner).try(:destroy!)
        end
      end
    end
  end
end
