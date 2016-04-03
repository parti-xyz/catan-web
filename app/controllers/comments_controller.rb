class CommentsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :post
  load_and_authorize_resource :comment, through: :post, shallow: true

  def create
    set_choice
    @comment.user = current_user
    @comment.save
    if @comment.choice.present?
      @comments_count = @comment.post.comments.by_choice(@comment.choice).count
    else
      @comments_count = @comment.post.comments.count
    end
    respond_to do |format|
      format.js
      format.html { redirect_to_origin }
    end
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
      if @comment.post.linkable? and !@comment.post.comments.exists?
        @comment.post.destroy!
        redirect_to @comment.post.issue
      else
        redirect_to_origin
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
