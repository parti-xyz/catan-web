class IssueForceDefaultJob < ApplicationJob
  include Sidekiq::Worker

  def perform(issue_id, organizer_user_id)
    issue = Issue.find_by(id: issue_id)
    return if issue.blank?

    organizer_user = User.find_by(id: organizer_user_id)
    return if organizer_user.blank?

    issue.group.members.each do |group_member|
      new_member = MemberIssueService.new(issue: issue, user: group_member.user, need_to_message_organizer: false, is_force: true).call
      if new_member.try(:persisted?)
        SendMessage.run(source: new_member, sender: organizer_user, action: :force_default_issue)
        MemberMailer.deliver_all_later_on_force_default(new_member, organizer_user)
      end
    end
  end
end
