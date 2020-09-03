class AnnouncePost < ActiveInteraction::Base
  object :post
  object :current_user, class: User, default: nil

  def execute
    announcement = post.announcement

    return if announcement.blank? or announcement.new_record?
    return unless announcement.announcing_mode.direct?

    requesting_direct_announced_users = User.parse_nicknames(announcement.direct_announced_user_nicknames)
    newbie_audiences(announcement, requesting_direct_announced_users)
    retired_audiences(announcement, requesting_direct_announced_users)

    announcement.reload
    ensure_noticed_for_current_user(announcement)

    result = {}
    if announcement.audiences.empty?
      announcement.destroy
      result[:not_member_users] = requesting_direct_announced_users
    else
      audience_user_ids = Member.where(id: announcement.audiences.select(:member_id)).pluck(:user_id).to_a

      result[:not_member_users] = requesting_direct_announced_users.reject { |user| audience_user_ids.include?(user.id) }
    end
    result
  end

  def newbie_audiences(announcement, requesting_direct_announced_users)
    members = post.issue.group.members.joins("LEFT OUTER JOIN audiences ON audiences.announcement_id = #{announcement.id} AND audiences.member_id = members.id")
      .where("audiences.id IS NULL")
      .where("members.user_id in (?)", requesting_direct_announced_users)

    members.each do |member|
      announcement.audiences.create(member: member)
    end
  end

  def retired_audiences(announcement, requesting_direct_announced_users)
    direct_audiences_ids = post.issue.group.members.where(user: requesting_direct_announced_users).select(:id)
    audiences = announcement.audiences
      .where("audiences.member_id not in (?)", direct_audiences_ids)
      .where("audiences.noticed_at IS NULL")
    audiences.destroy_all
  end

  def ensure_noticed_for_current_user(announcement)
    return if current_user.blank?

    current_group_member = current_user.smart_group_member(post.issue.group)
    current_audience = announcement.audiences.find_by(member: current_group_member)

    if current_audience.present?
      current_audience.noticed_at = DateTime.now
      current_audience.save
    end
  end
end
