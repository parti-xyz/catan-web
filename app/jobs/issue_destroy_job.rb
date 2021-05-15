class IssueDestroyJob < ApplicationJob
  include Sidekiq::Worker

  def perform(organizer_id, issue_id, message)
    outcome = IssueDestroy.run(user_id: organizer_id, issue_id: issue_id)
    unless outcome.valid?
      error = StandardError.new("IssueDestroyJob Fail : #{outcome.errors.inspect}")
      error.set_backtrace(caller)
      ExceptionNotifier.notify_exception(errors)
      return
    end

    issue = Issue.find_by(id: issue_id)
    return if issue.blank?

    mailing_user_ids = (issue.posts.pluck(:user_id) + issue.members.pluck(:user_id)).uniq

    mailing_user_ids.each do |user_id|
      PartiMailer.on_destroy(organizer.id, user_id, issue_id, message).deliver_later
    end
  end
end
