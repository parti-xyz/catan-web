module V1
  class Votings < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :votings do
      desc '투표합니다'
      oauth2
      params do
        requires :voting, type: Hash do
          requires :poll_id, type: Integer
          requires :choice, type: String
        end
      end
      post do
        permitted_params = permitted(params, :voting)
        @poll = Poll.find permitted_params[:poll_id]
        service = VotingPollService.new(poll: @poll, current_user: resource_owner)
        @voting = service.send(permitted_params[:choice].to_sym)
        if @voting.errors.any?
          error!(@voting.errors.full_messages, 500)
        end
      end
    end

  end
end
