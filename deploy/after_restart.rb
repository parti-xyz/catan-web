on_app_master do
  sudo "monit -g #{config.app}_sidekiq restart all"
end
