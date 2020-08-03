module GroupHelper
  def fetch_group request
    return nil if request.subdomain.blank?
    Group.includes(:labels).find_by_slug request.subdomain
  end
end
