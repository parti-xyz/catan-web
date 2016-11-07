module PartiUrlHelper
  def issue_home_path_or_url(issue, options = {})
    options.update(slug: issue.slug)
    if issue.group == current_group
      slug_issue_path(options)
    else
      issue_home_url(issue, options)
    end
  end

  def issue_home_url(issue, options = {})
    options.update(slug: issue.slug, subdomain: issue.group.try(:slug))
    slug_issue_url(options)
  end

  def issue_references_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_references_path(options)
  end

  def issue_polls_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_polls_path(options)
  end

  def issue_talks_path(issue, options = {})
    options.update(slug: issue.slug)

    if options.has_key? :section_id
      slug_issue_talks_with_section_path(options)
    else
      slug_issue_path(options)
    end
  end

  def issue_wikis_path(issue)
    slug_issue_wikis_path(slug: issue.slug)
  end

  def issue_users_path(issue)
    slug_issue_users_path(slug: issue.slug)
  end

  def user_gallery_path(user)
    slug_user_path(slug: user.slug)
  end

  def user_gallery_url(user)
    slug_user_url(slug: user.slug)
  end
end
