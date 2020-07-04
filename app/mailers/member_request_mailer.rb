class MemberRequestMailer < ApplicationMailer
  def self.deliver_all_later_on_create(member_request)
    return if member_request.blank?

    member_request.joinable.organizer_members.each do |organizer|
      on_create(organizer.id, member_request.id).deliver_later
    end
  end

  def on_create(organizer_id, member_request_id)
    organizer = Member.find_by id: organizer_id
    @organizer_user = organizer.try(:user)
    return if @organizer_user.blank?

    @member_request = MemberRequest.with_deleted.find_by id: member_request_id
    return if @member_request.blank?

    @organization = @member_request.joinable.group_for_message.organization

    mail(to: @organizer_user.email,
      from: build_from(@organization),
      subject: "[#{@organization.title}] #{@member_request.user.nickname}님이 #{@member_request.joinable.title} #{@member_request.joinable.model_name.human}에 가입요청했습니다")
  end

  def on_accept(member_request_id, user_id)
    @member_request = MemberRequest.with_deleted.find_by(id: member_request_id)
    return if @member_request.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    @organization = @member_request.joinable.group_for_message.organization

    mail(to: @member_request.user.email,
      from: build_from(@organization),
      subject: "[#{@organization.title}] #{@user.nickname}님이 #{@member_request.joinable.title} #{@member_request.joinable.model_name.human}에 가입요청을 승인했습니다")
  end

  def on_reject(member_request_id, user_id)
    @member_request = MemberRequest.with_deleted.find_by(id: member_request_id)
    return if @member_request.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    @organization = @member_request.joinable.group_for_message.organization

    mail(to: @member_request.user.email,
      from: build_from(@organization),
      subject: "[#{@organization.title}] #{@user.nickname}님이 #{@member_request.joinable.title} #{@member_request.joinable.model_name.human}에 가입요청을 거절했습니다")
  end
end
