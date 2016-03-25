class TalksController < ApplicationController
  include OriginPostable
  before_filter :authenticate_user!, except: [:show]
  load_and_authorize_resource

  def create
    redirect_to root_path and return if fetch_issue.blank?
    @talk.user = current_user
    @comment = build_comment
    @talk.save and ( @comment.blank? or @comment.save)
    redirect_to issue_home_path(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?
    @talk.update_attributes(talk_params)
    redirect_to issue_home_path(@issue)
  end

  def destroy
    @talk.destroy
    redirect_to issue_home_path(@talk.issue)
  end

  def show
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
    @issue ||= Issue.find_by title: params[:issue_title]
    @talk.issue = @issue.presence || @talk.issue
  end

  def build_comment
    body = params[:comment_body]
    return if body.blank?
    @talk.acting_as.comments.build(body: body, user: current_user)
  end
end
