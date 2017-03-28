class ApplicationMailer < ActionMailer::Base
  helper :application
  helper :parti_url

  default from: "feed@parti.xyz"
  layout 'email'
end
