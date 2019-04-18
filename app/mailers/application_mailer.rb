class ApplicationMailer < ActionMailer::Base
  helper :application
  helper :parti_url

  default from: "빠띠 <help@parti.xyz>"
  layout 'email'

  private

  def build_from(user)
    "#{"#{user.nickname} - 빠띠" if user.present?}<help@parti.xyz>"
  end
end
