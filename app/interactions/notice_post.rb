class NoticePost < ActiveInteraction::Base
  object :current_group, class: Group
  object :current_user, class: User
  object :announcement

  def execute
    member = current_group.member_of(current_user)
    audience = announcement.audiences.find_or_create_by(member: member)
    audience.noticed_at = DateTime.now
    audience.save

    audience
  end
end