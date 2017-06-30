module V1
  class Options < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :options do
      desc '제안합니다'
      oauth2
      params do
        requires :option, type: Hash do
          requires :survey_id, type: Integer
          requires :body, type: String
        end
      end
      post do
        permitted_params = permitted(params, :option)

        @option = Option.new permitted_params
        @survey = @option.survey
        error!(:forbidden, 410) and return if @survey.blank? or @survey.post.blank?

        @post = @survey.post
        error!(:forbidden, 403) and return if @post.issue.blank? or @post.issue.private_blocked?(current_user)
        error!('bad request', 500) and return if permitted_params[:body].blank?

        OptionSurveyService.new(option: @option, current_user: resource_owner).create

        if @option.errors.any?
          error!(@option.errors.full_messages, 500)
        end
      end
    end
  end
end
