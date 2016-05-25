%w(uploads google28d5b131c2b1660c.html sitemaps).each do |folder|
    run "ln -nfs #{config.shared_path}/public/#{folder} #{config.release_path}/public/#{folder}"
end
