class FeedbackSurveyService

  attr_accessor :option
  attr_accessor :current_user
  attr_accessor :selected

  def initialize(option:, current_user:, selected:)
    @option = option
    @current_user = current_user
    @selected = selected
  end

  def feedback
    survey = option.survey
    post = survey.post
    return if option.blank? or survey.blank? or post.blank?

    if survey.open?
      ActiveRecord::Base.transaction do
        previous_feedbacks = survey.feedbacks.where user: current_user

        if selected
          unless previous_feedbacks.exists?(option: option)
            feedback = create_feedback(option)
            unless survey.multiple_select?
              previous_feedbacks.where.not(option: option).destroy_all
            end
          end
        else
          if survey.multiple_select?
            previous_feedbacks.find_by(option: option).try(:destroy)
          else
            previous_feedbacks.destroy_all
          end
        end

        if post.generous_strok_by!(current_user, :feedback)
          post.issue.strok_by!(current_user, post)
        end
      end
    end
  end

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
