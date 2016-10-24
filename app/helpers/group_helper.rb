module GroupHelper
  def fetch_group request
    Group.find_by_slug request.subdomain
  end
end
