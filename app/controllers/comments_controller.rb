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
    unless params[:cancel]
      need_to_crawl = false
      ActiveRecord::Base.transaction do
        if params[:article_link].present? and @comment.linkable? and params[:article_link] != @comment.post.specific.link
          change_article
          need_to_crawl = true
        end
        @comment.assign_attributes(comment_params)
        unless @comment.save
          if @comment.errors.any?
            errors_to_flash(@comment)
            @comment.reload
          else
            return head(:internal_server_error)
          end
        end
      end
      crawl if need_to_crawl
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      @comment.destroy!
      if @comment.post.linkable? and !@comment.post.comments.exists?
        @comment.post.destroy!
      end
    end
  end

  private

  def redirect_to_origin
    redirect_to @comment.post.specific.specific_origin
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

    @previous_article.destroy! if @previous_article.comments.empty?
    # 반드시 post가 아니라 post_id를 세팅합니다.
    # 안그러면 해당 post의 comment count 숫자가 한 번 더 변경됩니다.
    @comment.post_id = @article.acting_as.id
  end

  def crawl
    if @article.present? and @article.link_source.crawling_status.not_yet?
      CrawlingJob.perform_async(@article.link_source.id)
    end
  end
end
