require 'exception_notification/rails'
require 'exception_notification/sidekiq'

ExceptionNotification.configure do |config|
  config.ignore_if do |exception, options|
    not(Rails.env.production?) and not(Rails.env.staging?)
  end

  config.add_notifier :slack, {
    username: "Catan #{Rails.env}",
    webhook_url: "https://hooks.slack.com/services/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",
    additional_parameters: {
      mrkdwn: true
    }
  }
end
