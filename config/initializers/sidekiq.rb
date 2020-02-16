if ENV['SIDEKIQ'] != 'true' && (Rails.env.development? || Rails.env.test?)
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
  ENV['SIDEKIQ'] = 'false'
else
  if Rails.env.production?
    redis_file = (Rails.root + 'config/redis.yml')

    if File.exists?(redis_file)
      redis_config = YAML.load_file(redis_file)[Rails.env]
      Sidekiq.configure_server do |config|
        config.redis = {
          url: "redis://#{redis_config['host']}:#{redis_config['port']}"
        }
      end
      Sidekiq.configure_client do |config|
        config.redis = {
          url: "redis://#{redis_config['host']}:#{redis_config['port']}"
        }
      end
    end
  else
    Sidekiq.configure_server do |config|
      config.redis = {namespace: "catan_web:#{Rails.env}"}
    end
    Sidekiq.configure_client do |config|
      config.redis = {namespace: "catan_web:#{Rails.env}"}
    end

  end

  schedule_file = "config/schedule.yml"

  if File.exists?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end

  ENV['SIDEKIQ'] = 'true'
end
