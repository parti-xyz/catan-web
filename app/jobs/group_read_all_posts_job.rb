class GroupReadAllPostsJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(user_id, group_id)
    outcome = GroupReadAllPosts.run(user_id: user_id, group_id: group_id)

    unless outcome.valid?
      Rails.logger.error outcome.errors.details.inspect
    end
  end
end
