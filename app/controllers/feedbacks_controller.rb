class FeedbacksController < ApplicationController
  before_filter :authenticate_user!

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

    if survey.open?
      previous_feedback = survey.feedbacks.find_by user: current_user

      if previous_feedback.present?
        previous_feedback.destroy
        if previous_feedback.option != @option
          feedback = create_feedback(@option)
        end
      else
        feedback = create_feedback(@option)
      end
    end

  end

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
