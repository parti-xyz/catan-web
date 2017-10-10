class FeedbacksController < ApplicationController
  before_action :authenticate_user!

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

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
