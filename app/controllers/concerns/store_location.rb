module StoreLocation
  def stored_location(group)
    if is_navigational_format?
      session.delete(stored_location_key(group))
    else
      session[stored_location_key(group)]
    end
  end

  def store_location(group)
    return unless request.get?
    return if request.fullpath.match("/users") or request.xhr? or request.fullpath.match("/mobile_app/")

    uri = parse_uri(request.fullpath)
    if uri
      path = [uri.path.sub(/\A\/+/, '/'), uri.query].compact.join('?')
      path = [path, uri.fragment].compact.join('#')
      session[stored_location_key(group)] = path
    end
  end

  def store_location_force(url)
    return unless request.get?
    return if request.xhr?
    session[stored_location_key(nil)] = url
  end

  private

  def parse_uri(location)
    location && URI.parse(location)
  rescue URI::InvalidURIError
    nil
  end

  def stored_location_key(group)
    key = "user_return_to"
    key = "#{group.slug}_#{key}" if group.present?
    key
  end
end
