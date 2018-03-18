class HashtagsController < ApplicationController
  def show
    @hashtag = params[:hashtag].strip.gsub(/( )/, '_').downcase

    watched_posts = Post.tagged_with(@hashtag).not_private_blocked_of_group(current_group, current_user).order_by_stroked_at

    if view_context.is_infinite_scrollable?
      if request.format.js?
        @previous_last_post = Post.find_by(id: params[:last_id])
        limit_count = (@previous_last_post.blank? ? 10 : 20)
        @posts = watched_posts.limit(limit_count).previous_of_post(@previous_last_post)

        current_last_post = @posts.last
        @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)
      end
    else
      @posts = watched_posts.page(params[:page])
      @recommend_posts = Post.of_undiscovered_issues(current_user).after(1.month.ago).hottest.order_by_stroked_at
    end
  end

  protected

  def mobile_navbar_title_show
    "##{@hashtag}" if @hashtag.present?
  end
end
