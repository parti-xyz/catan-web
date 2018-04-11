if !ENV['SIDEKIQ'] and (Rails.env.development? or Rails.env.test?)
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
else
  redis_config = YAML.load_file(Rails.root + 'config/redis.yml')[Rails.env]

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

  schedule_file = "config/schedule.yml"

  if File.exists?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end
end
