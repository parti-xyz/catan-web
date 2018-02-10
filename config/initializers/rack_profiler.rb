if Rails.env == 'development' and ENV['MINI_PROFILE'] == 'true'
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
