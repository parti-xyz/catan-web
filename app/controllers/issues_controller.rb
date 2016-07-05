class IssuesController < ApplicationController
  respond_to :js, :json, :html
  before_filter :authenticate_user!, only: [:create, :update, :destroy, :remove_logo, :remove_cover]
  before_filter :fetch_issue_by_slug, only: [:new_comments_count, :slug_home, :slug_users, :slug_articles, :slug_comments, :slug_opinions, :slug_talks, :slug_notes, :slug_wikis]
  load_and_authorize_resource

  def search
    @issues = Issue.search_for(params[:keyword])
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to issue_home_path(@issue)
  end

  def slug_home
    @last_comment = @issue.comments.newest

    previous_last_post = Post.find_by(id: params[:last_id])

    issus_posts = @issue.posts.order(last_touched_at: :desc)
    @posts = issus_posts.limit(25).previous_of_post(previous_last_post)

    current_last_post = @posts.last
    @is_last_page = (issus_posts.empty? or issus_posts.previous_of_post(current_last_post).empty?)
  end

  def slug_articles
    articles_page(@issue)
    prepare_issue_meta_tags
  end

  def slug_opinions
    opinions_page(@issue)
    prepare_issue_meta_tags
  end

  def slug_talks
    talks_page
    prepare_issue_meta_tags
  end

  def slug_notes
    notes_page(@issue)
    prepare_issue_meta_tags
  end

  def slug_wikis
  end

  def create
    @issue.makers.build(user: current_user)
    @watch = current_user.watches.build(watchable: @issue)
    ActiveRecord::Base.transaction do
      if !%w(all).include?(@issue.slug) and @issue.save and @watch.save
        redirect_to @issue
      else
        render 'new'
      end
    end
  end

  def update
    @issue.assign_attributes(issue_params)

    ActiveRecord::Base.transaction do
      if @issue.makers_nickname.present?
        @issue.makers.destroy_all
        @issue.makers_nickname.split(",").map(&:strip).each do |nickname|
          user = User.find_by(nickname: nickname)
          if user.present?
            @issue.makers.build(user: user)
          end
        end
      end
      if @issue.save
        @issue.makers.each do |maker|
          @watch = maker.user.watches.build(watchable: @issue)
          @watch.save
        end
        redirect_to @issue
      else
        errors_to_flash @issue
        render 'edit'
      end
    end
  end

  def destroy
    @issue.destroy
    redirect_to root_path
  end

  def remove_logo
    @issue.remove_logo!
    @issue.save
    redirect_to [:edit, @issue]
  end

  def remove_cover
    @issue.remove_cover!
    @issue.save
    redirect_to [:edit, @issue]
  end

  def slug_users
  end

  def exist
    respond_to do |format|
      format.json { render json: Issue.exists?(title: params[:title]) }
    end
  end

  def new_comments_count
    @count = @issue.comments.next_of(params[:first_id]).count
  end

  private

  def fetch_issue_by_slug
    @issue = Issue.find_by slug: params[:slug]
    if @issue.blank?
      @issue_by_title = Issue.find_by(title: params[:slug].titleize)
      if @issue_by_title.present?
        redirect_to @issue_by_title and return
      else
        render_404 and return
      end
    end
  end

  def issue_params
    params.require(:issue).permit(:title, :body, :logo, :cover, :slug, :basic, :makers_nickname)
  end

  def prepare_issue_meta_tags
    prepare_meta_tags title: meta_issue_title(@issue),
                      description: (@issue.body.presence || "#{@issue.title} 빠띠에서 즐거운 수다파티"),
                      image: @issue.cover_url
  end
end
