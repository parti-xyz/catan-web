if 'production' == config.framework_env
  on_utilities do
    sudo "monit -g #{config.app}_sidekiq restart all"
  end
else
  on_app_servers_and_utilities do
    sudo "monit -g #{config.app}_sidekiq restart all"
  end
end

