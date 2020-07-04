class ApplicationMailer < ActionMailer::Base
  helper :application
  helper :parti_url

  default from: "#{Organization.default.title} <#{Organization.default.email}>"
  layout 'email'

  private

  def build_from(organization)
    "#{organization.title} <#{organization.email}>"
  end
end
