class IssueForceDefaultJob
  include Sidekiq::Worker

  def perform(issue_id, user_id)
    issue = Issue.find_by(id: issue_id)
    return if issue.blank? or issue.indie_group?

    user = User.find_by(id: user_id)
    return if user.blank?

    issue.group.members.each do |member|
      MemberIssueService.new(issue: issue, user: member.user, need_to_message_organizer: false, is_force_default: true, organizer_user: user).call
    end
  end
end
