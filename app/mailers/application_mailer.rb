class ApplicationMailer < ActionMailer::Base
  helper :application
  helper :parti_url

  default from: "feed@parti.xyz"
  layout 'email'

  private

  def build_from(user)
    "#{"#{user.nickname} via 빠띠" if user.present?}<feed@parti.xyz>"
  end
end
