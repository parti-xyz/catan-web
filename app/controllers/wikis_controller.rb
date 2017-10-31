class WikisController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  authorize_resource
  before_action :load_post_and_wiki, except: [:index]

  def index
    having_wikis_posts_page(@issue, params[:status] || 'active')
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
  end

  private

  def load_post_and_wiki
    @post ||= Post.find_by id: params[:id]
    @post = nil if @post.private_blocked?(current_user)
    @wiki ||= @post.try(:wiki)
  end
end
