%w(uploads google28d5b131c2b1660c.html sitemaps).each do |folder|
    run "ln -nfs #{config.shared_path}/public/#{folder} #{config.release_path}/public/#{folder}"
end

%w(database.yml).each do |file|
    run "ln -nfs #{config.shared_path}/config/keep.#{file} #{config.shared_path}/config/#{file}"
end
