on_app_servers do
  worker_count = 1 # change as needed
  (0...worker_count).each do |i|
    sudo "monit stop all -g #{config.app}_sidekiq"
    sudo "/engineyard/bin/sidekiq #{config.app} stop #{config.framework_env} #{i}"
  end
end
