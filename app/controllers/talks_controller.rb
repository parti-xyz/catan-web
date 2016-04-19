class TalksController < ApplicationController
  include OriginPostable
  before_filter :authenticate_user!, except: [:show]
  load_and_authorize_resource

  def create
    redirect_to root_path and return if fetch_issue.blank?

    ActiveRecord::Base.transaction do
      @talk.user = current_user
      if @talk.save
        @comment = build_comment
        @comment.save if @comment.present?
      end
    end
    redirect_to params[:back_url].presence || issue_home_path(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?
    if @talk.update_attributes(talk_params)
      redirect_to @talk
    else
      render 'edit'
    end
  end

  def destroy
    @talk.destroy
    redirect_to issue_home_path(@talk.issue)
  end

  def show
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    else
      @issue = @talk.issue
      @talks = @issue.talks.recent.page 1
      @list_title = meta_issue_full_title(@issue)
      @list_url = issue_talks_path(@issue)
    end
    prepare_meta_tags title: @talk.title
  end

  helper_method :current_issue
  def current_issue
    @issue ||= @talk.try(:issue)
  end

  def postable_controller?
    true
  end

  private

  def talk_params
    params.require(:talk).permit(:title)
  end

  def fetch_issue
    @issue ||= Issue.find_by id: params[:talk][:issue_id]
    @talk.issue = @issue.presence || @talk.issue
  end

  def build_comment
    body = params[:comment_body]
    return if body.blank?
    @talk.acting_as.comments.build(body: body, user: current_user)
  end
end
