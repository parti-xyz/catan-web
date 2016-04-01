module PartiUrlHelper
  def issue_home_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_path(options)
  end

  def issue_home_url(issue)
    slug_issue_path(slug: issue.slug)
  end

  def issue_articles_path(issue)
    slug_issue_articles_path(slug: issue.slug)
  end

  def issue_comments_path(issue)
    slug_issue_path(slug: issue.slug)
  end

  def issue_opinions_path(issue)
    slug_issue_opinions_path(slug: issue.slug)
  end

  def issue_talks_path(issue)
    slug_issue_talks_path(slug: issue.slug)
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

  def tag_home_path(tag)
    show_tag_path(name: tag.name)
  end

end
