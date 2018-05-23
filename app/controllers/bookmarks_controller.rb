class BookmarksController < ApplicationController
  load_and_authorize_resource except: :destroy
  include DashboardGroupHelper

  def index
    authenticate_user!
    bookmarked_posts = Post.where(id: Bookmark.where(user: current_user).select(:post_id)).order_by_stroked_at

    if params[:group_slug].present?
      if params[:group_slug] == 'all'
        @dashboard_group = nil
        save_current_dashboard_group(nil)
      else
        @dashboard_group = Group.find_by(slug: params[:group_slug])
        save_current_dashboard_group(@dashboard_group)
      end
    else
      @dashboard_group = current_dashboard_group
    end

    bookmarked_posts = bookmarked_posts.of_group(@dashboard_group) if @dashboard_group.present?

    if view_context.is_infinite_scrollable?
      if request.format.js?
        @previous_last_post = Post.find_by(id: params[:last_id])
        limit_count = (@previous_last_post.blank? ? 10 : 20)
        @posts = bookmarked_posts.limit(limit_count).previous_of_post(@previous_last_post)

        current_last_post = @posts.last
        @is_last_page = (bookmarked_posts.empty? or bookmarked_posts.previous_of_post(current_last_post).empty?)
      end
    else
      @list_url = bookmarks_path
      @posts = bookmarked_posts.page(params[:page])
    end
  end

  def create
    return if @bookmark.post.bookmarked?(current_user)

    @bookmark.user = current_user
    if !@bookmark.save
      errors_to_flash(@bookmark)
    end
  end

  def destroy
    authenticate_user!
    @bookmark = Bookmark.find_by(id: params[:id])
    @post = Post.find_by(id: params[:post_id])
    return if @bookmark.blank?
    if !@bookmark.destroy
      errors_to_flash(@bookmark)
    end
  end

  private

  def bookmark_params
    params.require(:bookmark).permit(:post_id)
  end
end
