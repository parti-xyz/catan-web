%w(uploads google28d5b131c2b1660c.html naver9fdeaec0c18a2d5e8f426a702f2282e8.html sitemaps).each do |folder|
    run "ln -nfs #{config.shared_path}/public/#{folder} #{config.release_path}/public/#{folder}"
end
