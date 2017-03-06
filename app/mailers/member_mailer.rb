class MemberMailer < ApplicationMailer
  def self.deliver_all_later_on_create(member)
    return if member.blank?

    member.joinable.organizer_members.each do |organizer|
      on_create(organizer, member).deliver_later
    end
  end

  def on_create(organizer, member)
    @organizer_user = organizer.user
    @member = member
    mail(to: @organizer_user.email,
        subject: "[빠띠] #{member.user.nickname}님이 #{member.joinable.title} #{member.joinable.model_name.human}에 가입했습니다")
  end
end
