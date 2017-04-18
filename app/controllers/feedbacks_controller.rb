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
      ActiveRecord::Base.transaction do
        previous_feedbacks = survey.feedbacks.where user: current_user

        if survey.multiple_select?
          if previous_feedbacks.exists?(option: @option)
            previous_feedbacks.find_by(option: @option).destroy
          else
            feedback = create_feedback(@option)
          end
        else
          if previous_feedbacks.exists?(option: @option)
            previous_feedbacks.destroy_all
          else
            feedback = create_feedback(@option)
            previous_feedbacks.where.not(option: @option).destroy_all
          end
        end

        @post.generous_strok_by!(current_user)
      end
    end

  end

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
