module V1
  class Feedbacks < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :feedbacks do
      desc '투표합니다'
      oauth2
      params do
        requires :option_id, type: Integer
        requires :selected, coerce: Boolean
      end
      post do
        @option = Option.find_by id: params[:option_id]
        error!(:not_found, 410) and return if @option.blank?

        survey = @option.survey
        post = survey.post
        error!(:not_found, 410) and return if @option.blank? or survey.blank? or post.blank?
        error!(:forbidden, 403) and return if @option.try(:survey).try(:post).try(:private_blocked?, current_user)

        FeedbackSurveyService.new(option: @option, current_user: current_user, selected: params[:selected]).feedback

        if @option.errors.any?
          error!(@option.errors.full_messages, 500)
        end
      end
    end
  end
end
