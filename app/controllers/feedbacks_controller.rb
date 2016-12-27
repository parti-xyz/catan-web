class FeedbacksController < ApplicationController
  before_filter :authenticate_user!

  def create
    option = Option.find params[:option_id]
    survey = option.survey
    previous_feedback = survey.feedbacks.find_by user: current_user

    if previous_feedback.present?
      previous_feedback.destroy
      if previous_feedback.option != option
        feedback = create_feedback(option)
      end
    else
      feedback = create_feedback(option)
    end

    @post = Post.find_by! survey: survey
  end

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
