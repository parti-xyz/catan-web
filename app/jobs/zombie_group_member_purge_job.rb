class ZombieGroupMemberPurgeJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    Member.deleted.past_day(field: :deleted_at).where(joinable_type: Issue).each do |member|
      user = User.find_by(id: member.user_id)
      next if user.blank?

      issue = Issue.with_deleted.find_by(id: member.joinable_id)

      group = issue.try(:group)
      next if group == nil or group.private?

      issues = group.issues
      if !issues.any? { |issue| issue.member?(user) }
        member = group.member_of(user)
        member.try(:destroy)
      end
    end
  end
end
