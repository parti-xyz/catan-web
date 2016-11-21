module V1
  class Parties < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    helpers do
      def parties_joined
        resource_owner.member_issues.sort{ |a, b| a.compare_title(b) }
      end
    end

    namespace :parties do

      desc '내가 가입한 빠띠 목록을 내가 메이커인 빠띠를 포함하여 반환합니다'
      oauth2
      get :joined do
        present :parties, parties_joined, base_options
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

        present :parti, @first, base_options
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
      end
      get ':slug' do
        @issue = Issue.find_by!(slug: params[:slug])
        present :parti, @issue
      end

      desc '해당 빠띠의 모든 글을 반환합니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
        optional :last_id, type: Integer, desc: '이전 마지막 게시글 번호'
      end
      get ':slug/posts' do
        @issue = Issue.find_by(slug: params[:slug])
        base_posts = @issue.posts
        @last_post = base_posts.newest(field: :last_touched_at)

        previous_last_post = Post.with_deleted.find_by(id: params[:last_id])
        watched_posts = base_posts.order(last_touched_at: :desc)
        @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @has_more_item = (base_posts.any? and watched_posts.previous_of_post(current_last_post).any?)

        present :has_more_item, @has_more_item
        present :items, @posts, base_options.merge(type: :full)
      end

      desc '해당 빠띠의 멤버를 조회합니다'
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
      end
      get ':slug/members' do
        issue = Issue.find_by!(slug: params[:slug])
        present :members, issue.members, base_options
      end

      desc '가입했습니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
      end
      post ':slug/members' do
        @issue = Issue.find_by(slug: params[:slug])

        return if @issue.member?(resource_owner)
        @issue.members.build(user: resource_owner)
        @issue.save!
      end

      desc '탈퇴했습니다'
      oauth2
      params do
        requires :slug, type: String, desc: '빠띠의 slug'
      end
      delete ':slug/members' do
        @issue = Issue.find_by(slug: params[:slug])

        return if !@issue.member?(resource_owner)
        return if @issue.made_by? resource_owner
        ActiveRecord::Base.transaction do
          @issue.members.find_by(user: resource_owner).try(:destroy!)
        end
      end
    end
  end
end
