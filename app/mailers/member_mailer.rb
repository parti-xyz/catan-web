class MemberMailer < ApplicationMailer
  def self.deliver_all_later_on_create(member)
    return if member.blank?

    member.issue.makers.each do |maker|
      on_create(maker, member).deliver_later
    end
  end

  def on_create(maker, member)
    @maker_user = maker.user
    @member = member
    mail(to: @maker_user.email,
        subject: "[빠띠] #{member.user.nickname}님이 #{member.issue.title} 빠띠에 가입했습니다")
  end
end
