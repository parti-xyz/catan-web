class ApplicationMailer < ActionMailer::Base
  helper :application
  helper :parti_url
  include TruncateHtmlHelper

  default from: "feed@parti.xyz"
  layout 'email'
end
