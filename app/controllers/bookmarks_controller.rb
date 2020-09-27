class BookmarksController < ApplicationController
  load_and_authorize_resource
  include DashboardGroupHelper

  def index
    authenticate_user!

    base_bookmark = Bookmark.where(user: current_user).where(bookmarkable_type: 'Post')
    @search_tag_names = params[:tag_names].presence || []
    if @search_tag_names.any?
      base_bookmark = base_bookmark.tagged_with(@search_tag_names)
    end

    base_bookmarked_posts = Post.where(id: base_bookmark.select(:bookmarkable_id)).order_by_stroked_at

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

    @tags = current_user.owned_tags.where('taggings.taggable_type': 'Bookmark', 'taggings.context': 'tags')

    @tag_names = @search_tag_names + @tags.map(&:name)
    @tag_names.uniq!
  end

  def create
    return if @bookmark.bookmarkable&.bookmarked?(current_user)

    @bookmark.user = current_user
    if !@bookmark.save
      errors_to_flash(@bookmark)
    end
  end

  def destroy
    @post = Post.find_by(id: params[:post_id])
    @bookmark = @post.current_user_bookmark
    return if @bookmark.blank?
    if !@bookmark.destroy
      errors_to_flash(@bookmark)
    end
  end

  def add_tag
    return if params[:tag_name].blank?
    current_user.tag(@bookmark, with: @bookmark.all_tags_list + [params[:tag_name]], on: :tags)
  end

  def remove_tag
    return if params[:tag_name].blank?
    current_user.tag(@bookmark, with: @bookmark.all_tags_list - [params[:tag_name]], on: :tags)
  end

  private

  def bookmark_params
    params.require(:bookmark).permit(:bookmarkable_id, :bookmarkable_type)
  end
end
