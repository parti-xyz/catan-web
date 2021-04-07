module CookieHelper
  def cookies_get(key)
    cookies_env["#{Rails.env}.#{key}"]
  end

  def cookies_set(key, value)
    if value.present?
      cookies_env["#{Rails.env}.#{key}"] = {
        value: value,
        domain: :all,
        tld_length: 2,
      }
    else
      cookies.delete("#{Rails.env}.#{key}", domain: :all)
    end
  end

  private

  def cookies_env
    if Rails.env.production? || Rails.env.staging?
      cookies.signed
    else
      cookies
    end
  end
end