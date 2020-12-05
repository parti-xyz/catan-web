if ENV['SIDEKIQ'] != 'true' && (Rails.env.development? || Rails.env.test?)
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
  require 'sidekiq-status/testing/inline'
  ENV['SIDEKIQ'] = 'false'
else
  if Rails.env.production?
    Sidekiq.configure_server do |config|
      config.redis = {
        url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}",
        namespace: "catan_web:#{Rails.env}",
      }
      Sidekiq::Status.configure_server_middleware config
      Sidekiq::Status.configure_client_middleware config
    end
    Sidekiq.configure_client do |config|
      config.redis = {
        url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}",
        namespace: "catan_web:#{Rails.env}",
      }
      Sidekiq::Status.configure_client_middleware config
    end
  else
    Sidekiq.configure_server do |config|
      config.redis = { namespace: "catan_web:#{Rails.env}" }
      Sidekiq::Status.configure_server_middleware config
      Sidekiq::Status.configure_client_middleware config
    end
    Sidekiq.configure_client do |config|
      config.redis = { namespace: "catan_web:#{Rails.env}" }
      Sidekiq::Status.configure_client_middleware config
    end
  end

  schedule_file = 'config/schedule.yml'

  if File.exist?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end

  ENV['SIDEKIQ'] = 'true'
end
