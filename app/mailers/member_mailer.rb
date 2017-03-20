class MemberMailer < ApplicationMailer
  def self.deliver_all_later_on_create(member)
    return if member.blank?

    member.joinable.organizer_members.each do |organizer|
      on_create(organizer, member).deliver_later
    end
  end

  def on_admit(member_id, user_id)
    @member = Member.find_by(id: member_id)
    return if @member.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    mail(to: @member.user.email,
         subject: "[빠띠] #{@user.nickname}님이 회원님을 #{@member.joinable.title} #{@member.joinable.model_name.human}에서 가입시켰습니다.")
  end

  def on_create(organizer, member)
    @organizer_user = organizer.user
    @member = member
    mail(to: @organizer_user.email,
        subject: "[빠띠] #{member.user.nickname}님이 #{member.joinable.title} #{member.joinable.model_name.human}에 가입했습니다")
  end

  def on_ban(member_id, user_id)
    @member = Member.with_deleted.find_by(id: member_id)
    return if @member.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    mail(to: @member.user.email,
         subject: "[빠띠] #{@user.nickname}님이 회원님을 #{@member.joinable.title} #{@member.joinable.model_name.human}에서 탈퇴시켰습니다.")
  end
end
