class GroupMemberJob < ApplicationJob
  include Sidekiq::Worker

  def perform(group_id, user_ids)
    group = Group.find_by(id: group_id)
    return if group.blank?

    user_ids.each do |user_id|
      user = User.find_by(id: user_id)
      next if user.blank?

      MemberGroupService.new(group: group, user: user).call
    end
  end
end
