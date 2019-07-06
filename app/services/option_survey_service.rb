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
        @post.strok_by!(@current_user, :option)
        @post.issue.strok_by!(@current_user, @post)
        @post.issue.read_if_no_unread_posts!(@current_user)
        MessageService.new(@option).call
        OptionMailer.deliver_all_later_on_create(@option)
      end
    end
  end

  private

  def create_feedback(option)
    Feedback.create(user: current_user, option: option, survey: option.survey)
  end
end
