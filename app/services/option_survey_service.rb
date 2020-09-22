class OptionSurveyService

  attr_accessor :option
  attr_accessor :current_user
  attr_accessor :selected

  def initialize(option:, current_user:)
    @option = option
    @current_user = current_user
  end

  def create
    @option.user = @current_user
    survey = @option.survey
    return if survey.nil?
    return if survey.post.nil?
    return if survey.post.private_blocked? @current_user

    ActiveRecord::Base.transaction do
      @option.save! if survey.open?
      if @option.persisted?
        @post = survey.post
        @post.issue.deprecated_read_if_no_unread_posts!(@current_user)
        MessageService.new(@option).call
      end
    end
  end

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
