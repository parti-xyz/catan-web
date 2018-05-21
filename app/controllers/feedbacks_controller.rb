class FeedbacksController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    @post = Post.find params[:post_id]
    @option = Option.find_by id: params[:option_id]
    return if @option.blank?

    survey = @option.survey
    if @post != Post.find_by(survey: survey)
      render_404 and return
    end
    if @post.private_blocked?(current_user)
      render_404 and return
    end

    FeedbackSurveyService.new(option: @option, current_user: current_user, selected: params[:selected] == "true").feedback
  end

  def all_users
    @survey = Survey.find_by id: params[:survey_id]
    return if @survey.blank? and @survey.post.blank?
    @post = @survey.post

    render layout: nil
  end

  def users
    @option = Option.find_by id: params[:option_id]
    return if @option.blank?
    return unless @option.survey.visible_feedbacks?(current_user)

    render layout: nil
  end

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
