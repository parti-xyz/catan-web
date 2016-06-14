module PartiUrlHelper
  def watchable_home_path(watchable)
    self.send(:"slug_#{watchable.class.to_s.underscore}_path", watchable.slug)
  end

  def campaign_home_path(campaign, options = {})
    options.update(slug: campaign.slug)
    slug_campaign_path(options)
  end

  def issue_home_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_path(options)
  end

  def issue_home_url(issue)
    slug_issue_url(slug: issue.slug)
  end

  def issue_articles_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_articles_path(options)
  end

  def issue_opinions_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_opinions_path(options)
  end

  def issue_talks_path(issue)
    slug_issue_talks_path(slug: issue.slug)
  end

  def issue_wikis_path(issue)
    slug_issue_wikis_path(slug: issue.slug)
  end

  def issue_users_path(issue)
    slug_issue_users_path(slug: issue.slug)
  end

  def user_gallery_path(user)
    nickname_user_path(nickname: user.nickname)
  end

  def user_gallery_url(user)
    nickname_user_url(nickname: user.nickname)
  end

  def cancel_watchable_watches_path(watchable, options = {})
    self.send(:"cancel_#{watchable.class.to_s.underscore}_watches_path", watchable, options)
  end

  def watchable_watches_path(watchable, options = {})
    self.send(:"#{watchable.class.to_s.underscore}_watches_path", watchable, options)
  end
end
