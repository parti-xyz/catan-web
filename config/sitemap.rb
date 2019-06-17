Group.where.not(private: true).each do |group|
  SitemapGenerator::Sitemap.default_host = "https://#{group.subdomain}parti.xyz"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{group.slug}"
  SitemapGenerator::Sitemap.create do
    group.issues.where.not(private: true).alive.find_each do |issue|
      add slug_issue_path(slug: issue.slug), changefreq: 'daily', lastmod: issue.posts.newest.try(:updated_at) || issue.updated_at
    end
  end
end
