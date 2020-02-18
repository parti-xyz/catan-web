class OptionMailer < ApplicationMailer
  def self.deliver_all_later_on_create(option)
    return if option.blank?

    option.survey.post.messagable_users.each do |user|
      on_create(user.id, option.id).deliver_later
    end
  end

  def on_create(user_id, option_id)
    @option = Option.find_by(id: option_id)
    @user = User.find_by(id: user_id)
    return if @option.blank? or @user.blank? or !@user.enable_mailing_poll_or_survey? or @user == @option.user

    mail(from: build_from(@option.user),
         to: @user.email,
         subject: "[#{I18n.t('labels.app_name_human')}] #{@option.user.nickname}님이 새로운 제안을 올렸습니다 : #{@option.body}")
  end
end
