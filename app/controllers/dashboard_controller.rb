class DashboardController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js, :html

  def index
    watched_posts = current_user.watched_posts(current_group)
    @last_post = watched_posts.newest(field: :last_touched_at)

    previous_last_post = Post.find_by(id: params[:last_id])

    watched_posts = watched_posts.order(last_touched_at: :desc)
    @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

    current_last_post = @posts.last

    @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)
  end

  def intro
    @issue_tag_names = Issue.most_used_tags(20).map &:name
    @issue_tag_names += %w(정치 경제 사회 문화 교육 경제 환경 노동 페미니즘 인권 민주주의)
    @issue_tag_names.uniq!
  end

  def new_posts_count
    first_post = Post.find_by id: params[:first_id]
    if first_post.blank?
      @count = 0
    else
      @count = current_user.watched_posts(current_group).next_of_post(first_post).count
    end
  end
end
