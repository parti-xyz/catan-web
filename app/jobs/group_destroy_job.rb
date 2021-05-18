class GroupDestroyJob < ApplicationJob
  include Sidekiq::Worker

  def perform(organizer_id, group_id, message)
    organizer = User.find_by(id: organizer_id)
    group = Group.find_by(id: group_id)
    return if organizer.blank? || group.blank?

    ActiveRecord::Base.transaction do
      group.issues.each do |issue|
        outcome = IssueDestroy.run(user_id: organizer.id, issue_id: issue.id)
        unless outcome.valid?
          error = StandardError.new("GroupDestroyJob Fail : #{outcome.errors.inspect}")
          error.set_backtrace(caller)
          ExceptionNotifier.notify_exception(errors)
          return
        end
      end
      group.issues.reload
      group.destroy!
    end
  end
end
