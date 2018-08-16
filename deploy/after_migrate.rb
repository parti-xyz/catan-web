on_app_master do
  $stderr.puts "Seeding the data"
  run "cd #{config.release_path}"
  run "source #{config.shared_path}/config/env.custom && bundle exec rake db:seed_fu"
  run "source #{config.shared_path}/config/env.custom && bundle exec rake data:seed:group"
end
