class IssueCreateNotificationJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(issue_id, user_id)
    return if !Rails.env.production? && !Rails.env.staging?
    issue = Issue.find_by(id: issue_id)
    return if issue.blank?
    return if issue.private?

    creating_user = User.find_by(id: user_id)
    return if creating_user.blank?

    MessageService.new(issue, sender: creating_user, action: :create).call

    user_ids = issue.group.issue_create_messagable_users.select('users.id').map(&:id)
    user_ids.each_with_index do |user_id, index|
      PartiMailer.delay_until((5 * index).seconds.from_now).on_create(creating_user.id, user_id, issue.id)
    end
  end
end
