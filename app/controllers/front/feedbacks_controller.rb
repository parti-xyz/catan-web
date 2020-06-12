class Front::FeedbacksController < Front::BaseController
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
end