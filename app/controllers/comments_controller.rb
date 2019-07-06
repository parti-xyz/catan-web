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
    set_choice
    @comment.user = current_user

    if 'true' == params[:need_remotipart] and !remotipart_submitted?
      Rails.logger.info "DOUBLE REMOTIPART!!"
      head 200 and return
    end


    if @comment.save
      @comment.perform_mentions_async(:create)
    end
    @comments_count = @comment.post.comments_count
    if @comment.errors.any?
      errors_to_flash(@comment)
    end
    @comment.reload if @comment.persisted?
    respond_to do |format|
      format.js
      format.html { redirect_to_origin }
    end
  end

  def update
    unless params[:cancel]
      @comment.assign_attributes(comment_params)
      if @comment.save
        @comment.perform_mentions_async(:update)
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
  end

  def read
    if params[:comment_ids].present?
      @comments = Comment.where(id: params[:comment_ids].split(','))
      @comments.each do |comment|
        comment.read!(current_user)
      end

      Post.where(id: @comments.select(:post_id)).each do |post|
        member = post.issue.members.find_by(user: current_user)
        next if member.blank?
        post.beholders.find_or_create_by(user: member.user)
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

    params.require(:comment).permit(:body, :parent_id, file_sources_attributes: file_sources_attributes,)
  end

  def set_choice
    @voting = @comment.post.voting_by current_user
    @comment.choice = @voting.try(:choice)
  end

end
