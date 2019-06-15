module V1
  class Groups < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :groups do
      desc '각 공개 그룹의 최근 게시물 limit건과 각 공개 그룹 내의 채널에서 핀된 공지 게시물 전체를 반환합니다'
      params do
        requires :slug, type: String, desc: '그룹의 slug'
        optional :limit, type: Integer, desc: '최근 게시물 갯수', default: 10
      end
      get ':slug/highlight_posts' do
        target_group = Group.find_by(slug: params[:slug])
        error!(:not_found, 404) and return if target_group.private?

        parties = target_group.issues.where(private: false)
        pinned_posts = Post.where(issue: parties).where(pinned: true)
        recent_posts = Post.where(issue: parties).where(pinned: false).recent.limit(params[:limit])

        present :pinned, pinned_posts
        present :recent, recent_posts
      end
    end
  end
end
