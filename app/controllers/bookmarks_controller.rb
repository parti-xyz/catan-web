class BookmarksController < ApplicationController
  load_and_authorize_resource except: :destroy
  include DashboardGroupHelper

  def index
    authenticate_user!
    base_bookmarked_posts = Post.where(id: Bookmark.where(user: current_user).select(:post_id)).order_by_stroked_at

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

    if @dashboard_group.present?
      base_bookmarked_posts = base_bookmarked_posts.of_group(@dashboard_group)
      bookmarked_posts_group_map = { @dashboard_group => base_bookmarked_posts }
    else
      bookmarked_posts_group_map = base_bookmarked_posts.to_a.group_by { |post| post.issue.group }
    end

    @bookmarked_posts = []
    Group.where(id: bookmarked_posts_group_map.keys).sort_by_name.each do |group|
      bookmarked_posts_parti_map = bookmarked_posts_group_map[group].to_a.group_by { |post| post.issue }
      Issue.where(id: bookmarked_posts_parti_map.keys).sort_by_name.each do |issue|
        @bookmarked_posts << [issue, bookmarked_posts_parti_map[issue]]
      end
    end
  end

  def create
    return if @bookmark.post.bookmarked?(current_user)

    @bookmark.user = current_user
    if !@bookmark.save
      errors_to_flash(@bookmark)
    end
  end

  def update
    authenticate_user!
    @bookmark = Bookmark.find_by(id: params[:id])
    render_404 and return if @bookmark.blank?
    unless @bookmark.update_attributes(bookmark_params)
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

  def memo
    authenticate_user!
    @bookmark = Bookmark.find_by(id: params[:id])
  end

  private

  def bookmark_params
    params.require(:bookmark).permit(:post_id, :memo)
  end
end
