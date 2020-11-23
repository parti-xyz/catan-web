if 'production' == config.framework_env
  on_utilities do
    worker_count = 1 # change as needed
      (0...worker_count).each do |i|
        sudo "monit stop all -g #{config.app}_sidekiq"
        sudo "/engineyard/bin/sidekiq #{config.app} stop #{config.framework_env} #{i}"
      end
  end
else
  on_app_servers_and_utilities do
    worker_count = 1 # change as needed
    (0...worker_count).each do |i|
      sudo "monit stop all -g #{config.app}_sidekiq"
      sudo "/engineyard/bin/sidekiq #{config.app} stop #{config.framework_env} #{i}"
    end
  end
end


# create the shared packs folder. Should be a one-time only task
run "mkdir -p #{config.shared_path}/packs"
# link the shared packs folder to the release being deployed
# so that packs are found even if assets haven't changed
run "ln -nfs #{config.shared_path}/packs #{config.release_path}/public/packs"