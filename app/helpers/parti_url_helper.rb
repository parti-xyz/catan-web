module PartiUrlHelper
  def smart_issue_home_url(issue, options = {})
    new_options = options.merge(slug: issue.slug, subdomain: issue.group_subdomain)
    slug_issue_url(new_options)
  end

  def smart_issue_links_or_files_path(issue, options = {})
    slug_issue_links_or_files_path(options.merge(slug: issue.slug))
  end

  def smart_issue_polls_or_surveys_path(issue, options = {})
    slug_issue_polls_or_surveys_path(options.merge(slug: issue.slug))
  end

  def smart_issue_wikis_path(issue, options = {})
    slug_issue_wikis_path(options.merge(slug: issue.slug))
  end

  def smart_issue_folders_path(issue, folder = nil, options = {})
    slug_issue_folders_path(options.merge(slug: issue.slug, highlight_folder_id: folder.try(:id)))
  end

  def smart_issue_folders_url(issue, folder = nil, options = {})
    slug_issue_folders_url(options.merge(slug: issue.slug, highlight_folder_id: folder.try(:id)))
  end

  def smart_issue_members_path(issue, options = {})
    slug_issue_users_path(options.merge(slug: issue.slug))
  end

  def smart_issue_hashtag_url(issue, hashtag, options = {})
    slug_issue_hashtags_url(options.merge(slug: issue.slug, hashtag: hashtag, subdomain: issue.group_subdomain))
  end

  def smart_user_gallery_path(user)
    slug_user_path(slug: user.slug)
  end

  def smart_user_gallery_url(user, options = {})
    slug_user_url(options.merge(subdomain: nil, slug: user.slug))
  end

  def smart_post_url(post, options = {})
    polymorphic_url(post, options.merge(subdomain: post.issue.group_subdomain))
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
      if joinable.group.frontable?
        front_channel_url(subdomain: joinable.subdomain, id: joinable)
      else
        smart_issue_home_url(joinable, options)
      end
    else
      polymorphic_url(joinable, options)
    end
  end

  def smart_group_url(group, options = {})
    return root_url(options.merge(subdomain: group.subdomain))
  end

  def smart_group_issues_url(group, options = {})
    return issues_url(options.merge(subdomain: group.subdomain))
  end

  def smart_joinable_members_url(joinable, options = {})
    case joinable
    when Group
      smart_group_members_url(joinable, options)
    when Issue
      smart_issue_members_url(joinable, options)
    else
      polymorphic_url(joinable, options)
    end
  end

  def smart_group_members_url(group, options = {})
    group_members_url(options.merge(subdomain: group.subdomain))
  end

  def smart_issue_members_url(issue, options = {})
    slug_issue_users_url(options.merge(slug: issue.slug, subdomain: issue.group_subdomain))
  end

  def smart_front_post_url(post, options = {})
    front_post_path(post, options.merge(subdomain: post&.issue&.group_subdomain))
  end

  def smart_front_channel_url(issue, options = {})
    front_channel_path(issue, options.merge(subdomain: issue&.group_subdomain))
  end
end
