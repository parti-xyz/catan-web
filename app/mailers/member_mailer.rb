class MemberMailer < ApplicationMailer
  def on_create(member_id)
    @member = Member.find_by(id: member_id)
    return if @member.blank?

    @member.issue.makers.each do |maker|
      @maker_user = maker.user
      mail(to: @maker_user.email,
           subject: "[빠띠] #{@member.user.nickname}님이 #{@member.issue.title} 빠띠에 가입합니다")
    end
  end
end
