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
    @wiki.update_attributes(status: 'active')

    errors_to_flash(@post)
    redirect_to smart_wiki_url(@post.wiki)
  end

  def inactivate
    render_404 and return if @wiki.blank?
    @wiki.update_attributes(status: 'inactive')

    errors_to_flash(@post)
    redirect_to smart_wiki_url(@post.wiki)
  end

  def purge
    render_404 and return if @wiki.blank?
    @wiki.update_attributes(status: 'purge')

    errors_to_flash(@post)
    redirect_to smart_wiki_url(@post.wiki)
  end

  def histories
    render_404 and return if @wiki.blank?
    @history_page = @wiki.wiki_histories.recent.page params[:page]
    @current_history_back_post = @wiki.post
  end

  private

  def load_post_and_wiki
    @post ||= Post.find_by id: params[:id]
    @post = nil if @post.private_blocked?(current_user)
    @wiki ||= @post.try(:wiki)
  end

  def fixed_history_back_url_in_mobile_app
    if action_name == 'histories'
      smart_wiki_url(@wiki)
    end
  end
end
