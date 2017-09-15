module V1
  class Votings < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :votings do
      desc '투표합니다'
      oauth2
      params do
        requires :poll_id, type: Integer
        requires :choice, type: String
      end
      post do
        @poll = Poll.find_by id: params[:poll_id]
        error!(:not_found, 410) and return if @poll.blank? or @poll.post.blank?
        error!(:forbidden, 403) and return if @poll.post.private_blocked?(current_user)

        service = VotingPollService.new(poll: @poll, current_user: resource_owner)
        @voting = service.send(params[:choice].to_sym)
        if @voting.errors.any?
          error!(@voting.errors.full_messages, 500)
        end

        return_no_content
      end

      desc '찬성투표를 반환합니다'
      oauth2
      params do
        requires :poll_id, type: Integer
        optional :last_id, type: Integer, desc: '이전 마지막 투표 번호'
      end
      get 'agrees_of_poll' do
        poll = Poll.find_by(id: params[:poll_id])
        error!(:not_found, 410) and return if @poll.blank? or @poll.post.blank?
        error!(:forbidden, 403) and return if @poll.post.private_blocked?(current_user)
        votings_base = poll.votings.agreed.recent

        @votings = votings_base.limit(25)
        @votings = @votings.where('id < ?', params[:last_id]) if params[:last_id].present?
        current_last = @votings.last
        @has_more_item = (votings_base.any? and votings_base.where('id < ?', current_last.try(:id)).any?)

        present :has_more_item, @has_more_item
        present :items, @votings
      end

      desc '반대투표를 반환합니다'
      oauth2
      params do
        requires :poll_id, type: Integer
        optional :last_id, type: Integer, desc: '이전 마지막 투표 번호'
      end
      get 'disagrees_of_poll' do
        poll = Poll.find_by(id: params[:poll_id])
        error!(:not_found, 410) and return if @poll.blank? or @poll.post.blank?
        error!(:forbidden, 403) and return if @poll.post.private_blocked?(current_user)
        votings_base = poll.votings.disagreed.recent

        @votings = votings_base.limit(25)
        @votings = @votings.where('id < ?', params[:last_id]) if params[:last_id].present?
        current_last = @votings.last
        @has_more_item = (votings_base.any? and votings_base.where('id < ?', current_last.try(:id)).any?)

        present :has_more_item, @has_more_item
        present :items, @votings
      end

    end
  end
end
