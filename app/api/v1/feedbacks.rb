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
        logger.debug params.inspect
        @option = Option.find params[:option_id]
        survey = @option.survey
        post = survey.post
        error! if @option.blank? or survey.blank? or post.blank?

        FeedbackSurveyService.new(option: @option, current_user: current_user, selected: params[:selected]).feedback

        if @option.errors.any?
          error!(@option.errors.full_messages, 500)
        end
      end
    end
  end
end
