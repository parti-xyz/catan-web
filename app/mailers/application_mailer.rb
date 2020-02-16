class ApplicationMailer < ActionMailer::Base
  helper :application
  helper :parti_url

  default from: "#{I18n.t('labels.app_name_human')} <help@parti.xyz>"
  layout 'email'

  private

  def build_from(user)
    "#{"#{user.nickname} - #{I18n.t('labels.app_name_human')}" if user.present?}<help@parti.xyz>"
  end
end
