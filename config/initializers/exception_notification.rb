require 'exception_notification/rails'
require 'exception_notification/sidekiq'

ExceptionNotification.configure do |config|
  config.ignore_if do |exception, options|
    not(Rails.env.production?) and not(Rails.env.staging?)
  end

  config.add_notifier :slack, {
    username: "Catan #{Rails.env}",
    webhook_url: ENV["ERROR_SLACK_WEBHOOK_URL"],
    additional_parameters: {
      mrkdwn: true
    }
  }
end
