class UnblindJob < ApplicationJob
    include Sidekiq::Worker

    def perform(blind_id, issue_id, user_id)
      blind = Blind.find_by(id: blind_id)
      return if blind.present?

      if issue_id.present?
        Issue.find_by(id: issue_id).try(:posts) || Post.none
      else
        Post.all
      end.where(user_id: user_id).update_all(blind: false)
    end
  end