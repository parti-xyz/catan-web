module ApplicationHelper
  def byline(user, options={})
    return if user.nil?
    raw render(partial: 'users/byline', locals: options.merge(user: user))
  end

  def icon(classes)
    content_tag(:i, nil, class: classes)
  end

  def excerpt(text)
    truncate((strip_tags(text).try(:html_safe)), length: 200)
  end

  def date_f(date)
    if date.today?
      date.strftime("%H:%M")
    else
      date.strftime("%Y.%m.%d")
    end
  end

  def static_date_f(date)
    date.strftime("%Y.%m.%d %H:%M")
  end

  def striped_smart_format(text, html_options = {}, options = {})
    smart_format(strip_tags(text), html_options, options)
  end

  def smart_format(text, html_options = {}, options = {})
    parsed_text = simple_format(text, html_options, options).to_str
    parsed_text = parsed_text.gsub(Mentionable::HTML_PATTERN_WITH_AT) do |m|
      at_nickname = $1
      nickname = at_nickname[1..-1]
      user = User.find_by nickname: nickname
      if user.present?
        m.gsub($1, link_to($1, user_gallery_path(user), class: 'user__nickname--mentioned'))
      else
        m
      end
    end
    raw(auto_link(parsed_text,
      html: {class: 'auto_link', target: '_blank'},
      link: :urls,
      sanitize: false))
  end

  def asset_data_base64(path)
    content, content_type = parse_asset(path)
    base64 = Base64.encode64(content).gsub(/\s+/, "")
    "data:#{content_type};base64,#{Rack::Utils.escape(base64)}"
  end

  def parse_asset(path)
    if Rails.application.assets
      asset = Rails.application.assets.find_asset(path)
      throw "Could not find asset '#{path}'" if asset.nil?
      return asset.to_s, asset.content_type
    else
      name = Rails.application.assets_manifest.assets[path]
      throw "Could not find asset '#{path}'" if name.nil?
      content_type = MIME::Types.type_for(name).first.content_type
      content = open(File.join(Rails.public_path, 'assets', name)).read
      return content, content_type
    end
  end

  def screenable_article_title(article)
    article.hidden? ? icon('fa fa-exclamation-triangle') + " 빠띠메이커가 숨긴 링크입니다" : article.title
  end

  def video?(article)
    source = article.link_source

    source.present? and VideoInfo.usable?(source.url)
  end

  def video_embed_code(article)
    return unless video?(article)

    source = article.link_source
    raw(VideoInfo.new(source.url).embed_code({iframe_attributes: { class: 'article__body__video-content'}}))
  end

  def image_over_height(file, min_height)
    return false unless file.exists?
    size = FastImage.new(file.respond_to?(:url) ? file.url : file.path).size
    size.present? and size[1] > min_height
  end
end
