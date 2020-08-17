class AnnouncePost < ActiveInteraction::Base
  object :post

  def execute
    announcement = post.announcement

    return if announcement.blank? or announcement.new_record?
    return unless announcement.announcing_mode.direct?

    requesting_direct_announced_users = User.parse_nicknames(announcement.direct_announced_user_nicknames)

    newbie_members = post.issue.group.members.joins("LEFT OUTER JOIN audiences ON audiences.announcement_id = #{announcement.id} AND audiences.member_id = members.id", )
      .where('audiences.id IS NULL')
      .where('members.user_id in (?)', requesting_direct_announced_users)

    newbie_members.each do |member|
      announcement.audiences.create(member: member)
    end

    direct_audiences_ids = post.issue.group.members.where(user: requesting_direct_announced_users).select(:id)
    retired_audiences = announcement.audiences
    .where('audiences.member_id not in (?)', direct_audiences_ids)
    .where('audiences.noticed_at IS NULL')
    retired_audiences.destroy_all

    announcement.reload

    result = {}
    if announcement.audiences.empty?
      announcement.destroy
      result[:not_member_users] = requesting_direct_announced_users
    else
      audience_user_ids = Member.where(id: announcement.audiences.select(:member_id)).pluck(:user_id).to_a

      result[:not_member_users] = requesting_direct_announced_users.reject{ |user| audience_user_ids.include?(user.id) }
    end
    result
  end
end