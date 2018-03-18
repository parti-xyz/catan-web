require 'htmlentities'

module ApplicationHelper
  def body_class
    arr = ["app-#{params[:controller]}", "app-#{params[:controller]}-#{params[:action]}"]
    arr << "in-parti" if @issue.present?
    if current_group.present?
      arr << "in-group"
    else
      arr << "in-indie"
    end
    arr << (host_group.is_light_theme? ? "light-theme" : "dark-theme")
    arr << 'virtual-keyboard' if is_virtaul_keyboard?
    arr << 'ios' if browser.platform.ios?
    arr.join(' ')
  end

  def byline(user, options={})
    return if user.nil?
    raw render(partial: 'users/byline', locals: options.merge(user: user))
  end

  def icon(classes)
    content_tag(:i, nil, class: classes)
  end

  def excerpt(text, options = {})
    options[:length] = 130 unless options.has_key?(:length)

    result = text
    if options[:from_html]
      result = strip_tags(result)
      result = HTMLEntities.new.decode(result)
    end
    return result if result.blank?
    return result.truncate(options[:length], options)
  end

  def date_f(date)
    timeago_tag date, lang: :ko, limit: 3.days.ago
  end

  def static_date_f(date)
    date.strftime("%Y.%m.%d %H:%M")
  end

  def static_day_f(date)
    date.strftime("%Y.%m.%d")
  end

  def comment_format(issue, text, html_options = {}, options = {})
    options.merge!(wrapper_tag: 'span') if options[:wrapper_tag].blank?
    parsed_text = simple_format(h(text), html_options.merge(class: 'comment-body-line'), options).to_str
    parsed_text = parse_hashtags(issue, parsed_text)
    parsed_text = parse_mentions(parsed_text)
    Rinku.auto_link(parsed_text, :all,
      "class='auto_link' target='_blank'",
      nil).html_safe()
  end

  def post_body_format(issue, text)
    return text if text.blank?
    parsed_text = parse_hashtags(issue, text)
    parsed_text = parse_mentions(parsed_text)
    raw(parsed_text)
  end

  def decision_body_format(issue, text)
    return text if text.blank?
    parsed_text = simple_format(h(text)).to_str
    parsed_text = parse_hashtags(issue, parsed_text)
    parsed_text = parse_mentions(parsed_text)
    Rinku.auto_link(parsed_text, :all,
      "class='auto_link' target='_blank'",
      nil).html_safe()
  end

  HTML_AT_HASHTAG_REGEX = /(?:^|[[:space:]]|>|&nbsp;)(#[ㄱ-ㅎ가-힣a-z0-9_]+)/i

  def parse_hashtags(issue, text)
    text.gsub(HTML_AT_HASHTAG_REGEX) do |m|
      hashtag_with_hash = Regexp.last_match[1]
      hashtag = hashtag_with_hash[1..-1]

      url = smart_issue_hashtag_url(issue, hashtag)
      m.gsub(hashtag_with_hash, link_to(hashtag_with_hash, url, class: 'hashtag'))
    end
  end

  def parse_mentions(text)
    text.gsub(User::HTML_AT_NICKNAME_REGEX) do |m|
      at_nickname = Regexp.last_match[1]
      nickname = at_nickname[1..-1]
      if nickname == 'all'
        m.gsub(at_nickname, content_tag('span', at_nickname, class: 'user__nickname--mentioned'))
      else
        parsed = Rails.cache.fetch "view-user-at-sign-#{nickname}", race_condition_ttl: 30.seconds, expires_in: 12.hours do
          user = User.find_by nickname: nickname
          if user.present?
            url = slug_user_url(slug: user.slug)
            link_to(at_nickname, url, class: 'user__nickname--mentioned')
          else
            at_nickname
          end
        end
        m.gsub(at_nickname, parsed)
      end
    end
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

  def exist_asset?(path)
    if Rails.application.assets
      Rails.application.assets.find_asset(path).present?
    else
      Rails.application.assets_manifest.assets[path].present?
    end
  end

  def video_embed_code(post)
    return unless post.video_source?

    link_source = post.link_source
    raw(VideoInfo.new(link_source.url).embed_code({iframe_attributes: { class: 'post-reference-line__video-content'}}))
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

  def is_telegram_talkable?
    browser.device.mobile?
  end

  def is_hoverable?
    !browser.device.mobile? and !browser.device.tablet?
  end

  def is_selectpickerable?
    !browser.device.mobile? and !browser.device.tablet?
  end

  def is_infinite_scrollable?
    !is_mobile_app_get_request?(request)
  end

  def is_virtaul_keyboard?
    browser.device.mobile? || browser.device.tablet?
  end

  def has_error_attr?(object, name)
    object.respond_to?(:errors) && !(name.nil? || object.errors[name.to_s].empty?)
  end

  def error_class_str(object, name)
    'has-error' if has_error_attr?(object, name)
  end

  def upload_file_exists?(file_object)
    file_object.file.try(:exists?)
  end

  def render_markdown_to_html(wiki_body)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, quote: true, highlight: true, strikethrough: true)
    @wiki_markdown_view = markdown.render(wiki_body)
  end

  def issue_link_target_name(issue)
    '_blank' unless issue.displayable_group?(current_group)
  end

  def sort_issues_by_title(issues)
    issues.sort{ |a, b| a.compare_title(b) }
  end

  def smart_truncate_html(text, options = {})
    max_length = options[:length] || 100
    offset = options[:offset] || 100
    return text if (strip_tags(text).try(:length) || 0) < (max_length.to_i + offset)
    result = HTML_Truncator.truncate(text, max_length, options.merge(length_in_chars: true))
  end

  def meta_icons(model, *extras)
    tags = []
    tags << content_tag("i", '', class: ["fa", "fa-lock"], title: '비공개') if model.try(:private?)
    tags << content_tag("i", '', class: ["fa", "fa-bullhorn"], title: '오거나이저만 게시') if model.try(:notice_only?)
    extras.compact.each do |icon_name, title|
      tags << content_tag("i", '', class: ["fa", "fa-#{icon_name}"], title: title)
    end

    return '' if tags.empty?
    content_tag :span do
      tags.map { |tag| [tag, raw('&nbsp;')] }.flatten[0...-1].each do |tag|
        concat tag
      end
    end
  end

  def trim_count(value, limit = 99)
    if value > limit
      limit.to_s + '+'
    else
      value
    end
  end

  def is_webp? url
    return false if url.blank?

    '.webp' == File.extname(URI.parse(url).path)
  end

  def history_backable_in_mobile_app?
    return false unless is_mobile_app_get_request?(request)
    return false if history_base_page_in_mobile_app?
    !controller_path.start_with?('mobile_app/')
  end

  def group_my_parties_section_title(group)
    content_tag :span, class: ["group-parties-section-title"] do
      title = group.indie? ? "개인" : group.title_basic_format
      concat content_tag("span", title, class: ["group-title"])
      s_icon = meta_icons(group, (['star', '오거나이징하는 그룹'] if group.organized_by?(current_user)))
      if s_icon.present?
        concat raw('&nbsp;')
        concat s_icon
        concat raw('&nbsp;')
      end
      concat(content_tag("span", class: ["group-helptext"]) do
        concat content_tag("span", "이 오거나이징하는 ") if group.indie?
        concat content_tag("span", " 내 빠띠", class: ["text-nowrap"])
      end)
    end
  end

  def group_parties_section_title(group)
    content_tag :span, class: ["group-parties-section-title"] do
      title = group.indie? ? "개인" : group.title_basic_format
      concat content_tag("span", title, class: ["group-title"])
      s_icon = meta_icons(group)
      if s_icon.present?
        concat s_icon
        concat raw('&nbsp;')
      end
      concat content_tag("span", "#{Catan::SmartPostposition.new(title).adjust('이')} 오거나이징하는 빠띠", class: ["group-helptext"])
    end
  end

  def group_category_section_title(group)
    content_tag :span, class: ["group-parties-section-title"] do
      title = group.indie? ? "개인" : group.title_basic_format
      concat content_tag("span", title, class: ["group-title"])
      s_icon = meta_icons(group)
      if s_icon.present?
        concat s_icon
        concat raw('&nbsp;')
      end
      concat content_tag("span", "의 주제별 빠띠", class: ["group-helptext"])
    end
  end

  def user_subject_word(user)
    (user == current_user ? "내가" : "@#{user.nickname}님이")
  end

  def sidebar_opened?
    return false if controller_name == 'dashboard' and action_name == 'intro'
    cookies[:'sidebar-open'] == "true"
  end

  def root_domain
    URI(root_url(subdomain: nil)).host
  end

  def render_group_only_exist(path)
    return if host_group.blank? and path.blank?

    subpath = to_subpath(path)
    if exists_group_partial?(subpath)
      render "group_views/#{host_group.slug}#{subpath}"
    end
  end

  def render_group(path)
    return if host_group.blank? and path.blank?

    subpath = to_subpath(path)
    if exists_group_partial?(subpath)
      render "group_views/#{host_group.slug}#{subpath}"
    else
      render path
    end
  end

  private

  def to_subpath(path)
    return path if path.blank?
    (path[0] == '/' ? path : "/#{path}")
  end

  def partial_lookup_path(path)
    items = path.split('/')
    items[-1] = "_#{items[-1]}"
    items.join('/')
  end

  def exists_group_partial?(path)
    return false if host_group.blank?
    lookup_context.exists?("group_views/#{host_group.slug}/#{partial_lookup_path(path)}")
  end

  def main_column_tag(*additional_classes)
    content_tag :div, class: ((%w(col-xs-12 col-sm-8) << additional_classes).flatten.compact.uniq) do
      if block_given?
        yield
      end
    end
  end

  def aside_column_tag(*additional_classes)
    return if is_small_screen?
    content_tag :div, class: ((%w(hidden-xs col-sm-4) << additional_classes).flatten.compact.uniq) do
      if block_given?
        yield
      end
    end
  end
end
