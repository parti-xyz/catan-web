%w(database.yml).each do |file|
    run "ln -nfs #{config.shared_path}/config/keep.#{file} #{config.shared_path}/config/#{file}"
end
