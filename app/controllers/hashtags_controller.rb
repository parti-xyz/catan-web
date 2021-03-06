class HashtagsController < ApplicationController
  def show
    @hashtag = params[:hashtag].strip.gsub(/( )/, '_').downcase

    @search_type = params[:search_type]
    if @search_type.blank?
      @search_type = 'group' if current_group.present? or params[:group_id].present?
      @search_type = 'issue' if params[:issue_id].present?
    end
    @search_type = 'all' if @search_type.blank?

    if @search_type == 'issue'
      issue = Issue.find_by(id: params[:issue_id])
      render_404 and return if issue.blank?
      respond_to_html_only do
        redirect_to smart_issue_hashtag_url(issue, @hashtag)
      end and return
    end

    if @search_type == 'group'
      @current_search_group = current_group
      if params[:group_id].present?
        @current_search_group = Group.find_by(id: params[:group_id])
      end
      render_404 and return if @current_search_group.blank?
      render_403 and return if @current_search_group.private_blocked?

      if current_group != @current_search_group
        respond_to_html_only do
          redirect_to hashtag_url(subdomain: @current_search_group.subdomain, hashtag: @hashtag)
        end and return
      end
    end

    watched_posts = Post.tagged_with(@hashtag).of_searchable_issues(current_user).order(last_stroked_at: :desc)
    watched_posts = watched_posts.of_group(@current_search_group) if @current_search_group.present?

    if request.format.js?
      if params[:previous_post_last_stroked_at_timestamp].present?
        @previous_last_post_stroked_at_timestamp = params[:previous_post_last_stroked_at_timestamp].to_i
      end

      limit_count = (@previous_last_post_stroked_at_timestamp.blank? ? 10 : 20)
      @posts = watched_posts.limit(limit_count).previous_of_time(@previous_last_post_stroked_at_timestamp).to_a

      current_last_post = @posts.last
      if current_last_post.present?
        @posts += watched_posts.where(last_stroked_at: current_last_post.last_stroked_at).where.not(id: @posts).to_a
      end

      @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)
    end
  end

  protected

  def mobile_navbar_title_show
    "##{@hashtag}" if @hashtag.present?
  end
end
