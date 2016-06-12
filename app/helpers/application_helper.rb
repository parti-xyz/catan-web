module ApplicationHelper
  def byline(user, options={})
    return if user.nil?
    raw render(partial: 'users/byline', locals: options.merge(user: user))
  end

  def icon(classes)
    content_tag(:i, nil, class: classes)
  end

  def excerpt(text, options = {})
    options[:length] = 130 unless options.has_key?(:length)
    truncate((strip_tags(text).try(:html_safe)), options)
  end

  def date_f(date)
    timeago_tag date, lang: :ko, limit: 3.days.ago
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

  def screenable_article_title(article, length: 0)
    article.hidden? ? icon('fa fa-exclamation-triangle') + " 빠띠메이커가 숨긴 자료입니다" : (length == 0 ? article.title : truncate(article.title, length: length))
  end

  def article_card_image(article)
    article.image.file.try(:exists?) ? article.image.md.url : asset_path('default_link_source_image_card.png')
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

  def link_to_if_with_block condition, options, html_options={}, &block
    if condition
      link_to options, html_options, &block
    else
      capture &block
    end
  end

  def is_small_screen?
    browser.device.mobile?
  end

  def is_kakao_talkable?
    browser.device.mobile?
  end

  def is_hoverable?
    !browser.device.mobile? and !browser.device.tablet?
  end

  def editable_issues_continents(user)
    watched = user.watched_issues.map { |issue| [issue.title, issue.id, {data: {logo: issue.logo.xs.url}}] }
    featured = Issue.basic_issues.select { |issue| !user.watched_issues.include?(issue) }.map { |issue| [issue.title, issue.id, {data: {logo: issue.logo.xs.url}}] }

    result = []
    result << ['참여 중인 빠띠', watched] if watched.any?
    result << ['기본 빠띠', featured] if featured.any?
    result << ['마땅한 빠띠가 없으세요?', [['', 0, {'data-url': issues_path, 'data-label': '<div><i class="fa fa-info-circle"/> 관심있는 빠띠에 참여해 보세요. <b style="white-space:nowrap">전체빠띠로 이동 <i class="fa fa-arrow-right"/></b></div>'}]]]
  end

  def jumpable_issues_continents(user)
    making = user.making_issues.hottest.map { |issue| {id: issue.id, text: issue.title, logo: issue.logo.xs.url, url: issue_home_path(issue)} }
    watched = user.only_watched_issues.hottest.map { |issue| {id: issue.id, text: issue.title, logo: issue.logo.xs.url, url: issue_home_path(issue)} }

    result = []
    result << {text: '메이커인 빠띠', children: making} if making.any?
    result << {text: '참여 중인 빠띠', children: watched} if watched.any?
    return result
  end

  def has_error_attr?(object, name)
    object.respond_to?(:errors) && !(name.nil? || object.errors[name.to_s].empty?)
  end

  def error_class_str(object, name)
    'has-error' if has_error_attr?(object, name)
  end
end
