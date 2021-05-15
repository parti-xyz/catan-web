class IssueDestroy < ActiveInteraction::Base
  integer :user_id
  integer :issue_id

  validates :user_id, presence: true
  validates :issue_id, presence: true

  def execute
    organizer = User.find_by(id: user_id)
    issue = Issue.find_by(id: issue_id)
    return if organizer.blank? or issue.blank?

    ActiveRecord::Base.transaction do
      issue.update_attributes(destroyer: organizer)
      issue.posts.each do |post|
        PostDestroyService.new(post).call
      end
      Message.where(messagable: issue.members_with_deleted).destroy_all
      Message.where(messagable: issue.member_requests_with_deleted).destroy_all

      User.where(id: issue.members.select(:user_id)).update_all(member_issues_changed_at: DateTime.now)
      issue.destroy

      errors.merge!(issue.errors)
    end
  end
end
