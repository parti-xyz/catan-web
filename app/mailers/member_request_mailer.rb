class MemberRequestMailer < ApplicationMailer
  def self.deliver_all_later_on_create(member_request)
    return if member_request.blank?

    member_request.issue.makers.each do |maker|
      on_create(maker, member_request).deliver_later
    end
  end

  def on_create(maker, member_request)
    @maker_user = maker.user
    @member_request = member_request
    mail(to: @maker_user.email,
         subject: "[빠띠] #{@member_request.user.nickname}님이 #{@member_request.issue.title} 빠띠에 가입요청했습니다")
  end

  def on_accept(member_request_id, user_id)
    @member_request = MemberRequest.with_deleted.find_by(id: member_request_id)
    return if @member_request.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    mail(to: @member_request.user.email,
         subject: "[빠띠] #{@user.nickname}님이 #{@member_request.issue.title} 빠띠에 가입요청을 승인했습니다")
  end

  def on_cancel(member_request_id, user_id)
    @member_request = MemberRequest.with_deleted.find_by(id: member_request_id)
    return if @member_request.blank?

    @user = User.find_by(id: user_id)
    return if @user.blank?

    mail(to: @member_request.user.email,
         subject: "[빠띠] #{@user.nickname}님이 #{@member_request.issue.title} 빠띠에 가입요청을 거절했습니다")
  end
end
