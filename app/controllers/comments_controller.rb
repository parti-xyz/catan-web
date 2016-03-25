class CommentsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :post
  load_and_authorize_resource :comment, through: :post, shallow: true

  def create
    set_choice
    @comment.user = current_user
    @comment.save

    redirect_to_origin
  end

  def update
    ActiveRecord::Base.transaction do
      if params[:article_link].present? and @comment.linkable? and params[:article_link] != @comment.post.specific.link
        change_article
      end
      if @comment.update_attributes(comment_params)
        redirect_to_origin
      else
        render 'edit'
      end
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      @comment.destroy
      unless @comment.post.reload.comments.exists?
        @comment.post.destroy!
        redirect_to @comment.post.issue
      else
        redirect_to @comment.post.specific
      end
    end
  end

  private

  def redirect_to_origin
    redirect_to @comment.post.specific.origin
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def set_choice
    if @comment.post.specific.respond_to? :voted_by
      @vote = @comment.post.specific.voted_by current_user
      @comment.choice = @vote.try(:choice)
    end
  end

  def change_article
    @previous_article = @comment.post.specific
    @article = @comment.issue.articles.find_or_initialize_by(link: params[:article_link]) do |new_article|
      source = LinkSource.find_or_create_by! url: new_article.link
      new_article.link_source = source
      new_article.user ||= current_user
    end
    @article.save!

    if @article.link_source.crawling_status.not_yet?
      CrawlingJob.perform_async(@article.link_source.id)
    end

    @previous_article.destroy! if @previous_article.comments.empty?
    @comment.post = @article.acting_as
  end
end
