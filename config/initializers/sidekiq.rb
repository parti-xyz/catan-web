if !ENV['SIDEKIQ'] and (Rails.env.development? or Rails.env.test?)
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
else
  Sidekiq.configure_server do |config|
    config.redis = {namespace: "catan_web:#{Rails.env}"}
  end
  Sidekiq.configure_client do |config|
    config.redis = {namespace: "catan_web:#{Rails.env}"}
  end

  schedule_file = "config/schedule.yml"

  if File.exists?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end
end
