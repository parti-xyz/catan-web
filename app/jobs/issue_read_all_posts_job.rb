class IssueReadAllPostsJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(user_id, issue_id)
    outcome = IssueReadAll.run(user_id: user_id, issue_id: issue_id)

    unless outcome.valid?
      Rails.logger.error outcome.errors.details.inspect
    end
  end
end
