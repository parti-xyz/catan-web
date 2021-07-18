class CommentsController < ApplicationController
  include ActionView::RecordIdentifier
  include DomHelper

  before_action :authenticate_user!, except: :show
  load_and_authorize_resource :post
  load_and_authorize_resource :comment, through: :post, shallow: true

  def show
    redirect_to smart_post_url(@comment.post, anchor: comment_line_anchor_dom_id(@comment))
  end

  def create
    if @post.issue.blank? or private_blocked?(@post.issue)
      render_404 and return
    end

    unless @post.issue.commentable? current_user
      render_403 and return
    end

    set_choice
    @comment.user = current_user
    @comment.last_author = current_user

    if 'true' == params[:need_remotipart] and !remotipart_submitted?
      Rails.logger.info "DOUBLE REMOTIPART!!"
      head 200 and return
    end

    if @comment.save
      @comment.perform_messages_with_mentions_async(:create_comment)
    end
    @comments_count = @comment.post.comments_count
    if @comment.errors.any?
      errors_to_flash(@comment)
      head 204 and return if helpers.explict_front_namespace?
    end

    if helpers.explict_front_namespace?
      flash.now[:notice] = t('activerecord.successful.messages.created')

      render(partial: "/front/posts/show/comments", locals: { current_issue: @post.issue, current_post: @post })
    else
      @comment.reload if @comment.persisted?
      respond_to do |format|
        format.js
        format.html { redirect_to_origin }
      end
    end
  end

  def update
    unless params[:cancel]
      @comment.assign_attributes(comment_params)
      @comment.last_author = current_user
      if @comment.save
        @comment.perform_messages_with_mentions_async(:update_comment)
      else
        if @comment.errors.any?
          errors_to_flash(@comment)
          @comment.reload
        else
          return head(:internal_server_error)
        end
      end
    end
    @comment.reload if @comment.persisted?

    if helpers.explict_front_namespace?
      flash.now[:notice] = t('activerecord.successful.messages.created')

      render(partial: "/front/posts/show/comments", locals: { current_issue: @comment.post.issue, current_post: @comment.post })
    else
      render
    end
  end

  def destroy
    if @comment.children.any?
      @comment.touch(:almost_deleted_at)
    else
      @comment.destroy!
      if @comment.parent.present? and @comment.parent.almost_deleted? and @comment.parent.children.empty?
        @comment.parent.destroy!
      end
    end

    if helpers.explict_front_namespace?
      flash.now[:notice] = t('activerecord.successful.messages.deleted')

      render(partial: "/front/posts/show/comments", locals: { current_issue: @comment.post.issue, current_post: @comment.post })
    else
      render
    end
  end

  def read
    if params[:comment_ids].present?
      @comments = Comment.where(id: params[:comment_ids].split(','))
      @comments.each do |comment|
        comment.read!(current_user)
      end
    end

    head 200, content_type: "text/html"
  end

  private

  def redirect_to_origin
    redirect_to @comment.post
  end

  def comment_params
    file_sources = params[:comment][:file_sources_attributes]
    if file_sources.try(:any?)
      file_sources_attributes = FileSource.require_attrbutes

      index = 0
      file_sources.each do |file_source|
        params[:comment][:file_sources_attributes][file_source[0]]["seq_no"] = index
        index += 1
      end
    end

    params.require(:comment).permit(:body, :is_html, :parent_id, :wiki_history_id, :is_decision, file_sources_attributes: file_sources_attributes,)
  end

  def set_choice
    @voting = @comment.post.voting_by current_user
    @comment.choice = @voting.try(:choice)
  end

  def private_blocked?(issue)
    return true if issue.blank?
    issue.private_blocked?(current_user)
  end
end
