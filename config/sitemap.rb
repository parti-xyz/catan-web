SitemapGenerator::Sitemap.default_host = "http://parti.xyz"
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'
SitemapGenerator::Sitemap.create do
  Issue.find_each do |issue|
    add issue_home_path_or_url(issue), changefreq: 'daily', lastmod: issue.posts.newest.try(:updated_at) || issue.updated_at
  end
end
