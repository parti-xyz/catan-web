class WikisController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  authorize_resource
  before_action :load_post_and_wiki, except: [:index]

  def index
    how_to = params[:status] == 'inactive' ? :inactive : :active
    @posts = Post.having_wiki(how_to.to_s).not_private_blocked_of_group(current_group, current_user).order_by_stroked_at.page(params[:page]).per(3*5)
  end

  def activate
    render_404 and return if @wiki.blank?

    ActiveRecord::Base.transaction do
      @wiki.update_attributes(last_author: current_user, status: 'active')
      @post = @wiki.post
      @post.strok_by!(current_user)
      @post.issue.strok_by!(current_user, @post)
      @post.issue.deprecated_read_if_no_unread_posts!(current_user)
    end

    errors_to_flash(@post)
    redirect_to smart_post_url(@post)
  end

  def inactivate
    render_404 and return if @wiki.blank?

    ActiveRecord::Base.transaction do
      @wiki.update_attributes(last_author: current_user, status: 'inactive')
      @post = @wiki.post
      @post.strok_by!(current_user)
      @post.issue.strok_by!(current_user, @post)
      @post.issue.deprecated_read_if_no_unread_posts!(current_user)
    end

    errors_to_flash(@post)
    redirect_to smart_post_url(@post)
  end

  def purge
    render_404 and return if @wiki.blank?

    ActiveRecord::Base.transaction do
      @wiki.update_attributes(last_author: current_user, status: 'purge')
      @post = @wiki.post
      @post.strok_by!(current_user)
      @post.issue.strok_by!(current_user, @post)
      @post.issue.deprecated_read_if_no_unread_posts!(current_user)
    end

    errors_to_flash(@post)
    redirect_to smart_post_url(@post)
  end

  def histories
    render_404 and return if @wiki.blank?
    @history_page = @wiki.wiki_histories.recent.page params[:page]
    @current_history_back_post = @wiki.post
  end

  private

  def load_post_and_wiki
    @post ||= Post.find_by id: params[:id]
    @post = nil if @post.present? and @post.private_blocked?(current_user)
    @wiki ||= @post.try(:wiki)
  end
end
