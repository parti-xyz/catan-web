module DashboardGroupHelper
  def current_dashboard_group
    return @__current_dashboard_group if @__current_dashboard_group.present?

    slug = cookies[:'current_dashboard_group']
    @__current_dashboard_group = (slug.present? ? Group.find_by(slug: slug) : nil)
    @__current_dashboard_group
  end

  def save_current_dashboard_group(group)
    if group.blank?
      cookies[:'current_dashboard_group'] = nil
    else
      cookies[:'current_dashboard_group'] = group.slug
    end
  end
end
