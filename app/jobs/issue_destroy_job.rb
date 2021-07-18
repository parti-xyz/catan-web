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

    User.where(id: issue.members.select(:user_id)).update_all(member_issues_changed_at: Time.current)
    issue.destroy!
  end
end
