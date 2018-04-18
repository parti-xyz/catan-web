on_utilities do
  sudo "monit -g #{config.app}_sidekiq restart all"
end
