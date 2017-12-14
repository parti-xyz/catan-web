class MemberMailer < ApplicationMailer
  def self.deliver_all_later_on_create(member)
    return if member.blank?

    member.joinable.organizer_members.each do |organizer|
      on_create(organizer.id, member.id).deliver_later
    end
  end

  def self.deliver_all_later_on_force_default(member, organizer_user)
    return if member.blank?
    return if organizer_user.blank?
    on_force_default(member.id, organizer_user.id).deliver_later
  end

  def on_admit(member_id, user_id)
    @member = Member.find_by(id: member_id)
    return if @member.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    mail(to: @member.user.email,
         subject: "[빠띠] #{@user.nickname}님이 회원님을 #{@member.joinable.title} #{@member.joinable.model_name.human}에서 가입시켰습니다.")
  end

  def on_create(organizer_id, member_id)
    @organizer = Member.find_by(id: organizer_id)
    return if @organizer.blank?
    @organizer_user = @organizer.user

    @member = Member.find_by(id: member_id)
    return if @member.blank?

    return unless @organizer_user.try(:enable_mailing_member?)

    mail(to: @organizer_user.email,
        subject: "[빠띠] #{@member.user.nickname}님이 #{@member.joinable.title} #{@member.joinable.model_name.human}에 가입했습니다")
  end

  def on_ban(member_id, user_id)
    @member = Member.with_deleted.find_by(id: member_id)
    return if @member.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    mail(to: @member.user.email,
         subject: "[빠띠] #{@user.nickname}님이 회원님을 #{@member.joinable.title} #{@member.joinable.model_name.human}에서 탈퇴시켰습니다.")
  end

  def on_force_default(member_id, organizer_user_id)
    @member = Member.find_by(id: member_id)
    return if @member.blank?

    @user = User.find_by(id: organizer_user_id)
    return if @user.blank?

    mail(to: @member.user.email,
         subject: "[빠띠] #{@user.nickname}님이 #{@member.joinable.title} #{@member.joinable.model_name.human}를 자동으로 가입되도록 설정했습니다. 해당 #{@member.joinable.model_name.human}에 가입되셨습니다.")
  end
end
