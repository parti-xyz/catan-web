module PartiUrlHelper
  def issue_home_path_or_url(issue, options = {})
    options.update(slug: issue.slug)
    if issue.displayable_group?(current_group)
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

  def issue_posts_path(issue, options = {})
    options.update(slug: issue.slug)

    slug_issue_path(options)
  end

  def issue_wikis_path(issue)
    slug_issue_wikis_path(slug: issue.slug)
  end

  def issue_users_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_users_path(options)
  end

  def user_gallery_path(user)
    slug_user_path(slug: user.slug)
  end

  def user_gallery_url(user)
    slug_user_url(slug: user.slug)
  end

  def smart_post_path_or_url(post, options = {})
    if post.issue.displayable_group?(current_group)
      polymorphic_path(post, options)
    else
      smart_post_url(post, options)
    end
  end

  def smart_post_url(post, options = {})
    options.update(subdomain: post.issue.group.try(:slug))
    polymorphic_url(post, options)
  end

  def smart_members_or_member_requests_parti_path(issue, options = {})
    if issue.private?
      issue_member_requests_path(issue, options)
    else
      issue_members_path(issue, options)
    end
  end

  def smart_joinable_url(joinable, options = {})
    case joinable
    when Group
      smart_group_url(joinable, options)
    when Issue
      issue_home_url(joinable, options)
    else
      polymorphic_url(joinable, options)
    end
  end

  def smart_group_url(group, options = {})
    root_url(options.merge(subdomain: group.slug))
  end
end
