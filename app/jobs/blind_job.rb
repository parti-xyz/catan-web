class BlindJob < ApplicationJob
    include Sidekiq::Worker

    def perform(blind_id)
      blind = Blind.find_by(id: blind_id)
      return if blind.blank?

      if blind.issue.present?
        blind.issue.posts
      else
        Post.all
      end.where(user_id: blind.user_id).update_all(blind: true)
    end
  end