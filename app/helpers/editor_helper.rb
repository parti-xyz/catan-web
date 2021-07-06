module EditorHelper
  DEFAULT_OPTION = {
    image: {
      rule_file_size: 10.megabytes,
      upload_url: Rails.application.routes.url_helpers.editor_assets_path,
    },
  }

  def editor(body, options = {})
    merged_options = DEFAULT_OPTION.deep_merge(options)
    tag.div(data: { target: 'editor2-form.menuBarWrapper' }) do
      concat(tag.div(data: { target: 'editor2-form.menuBarSpacer' }))
      concat(tag.div(data: { target: 'editor2-form.menuBar' },
      class: 'p-1 border bg-white',
      style: 'z-index: 10') do
        add_menu('paragraph') do
          tag.i(class: 'fa fa-fw fa-paragraph')
        end
        add_menu('h1') do
          tag.span('H1', class: 'fa fa-fw font-weight-bold')
        end
        add_menu('h2') do
          tag.span('H2', class: 'fa fa-fw font-weight-bold')
        end
        add_menu('h3') do
          tag.span('H3', class: 'fa fa-fw font-weight-bold')
        end
        add_separator
        add_menu('bold') do
          tag.i(class: 'fa fa-fw fa-bold')
        end
        add_menu('italic') do
          tag.i(class: 'fa fa-fw fa-italic')
        end
        add_menu('strike') do
          tag.i(class: 'fa fa-fw fa-strikethrough')
        end
        add_menu('underline') do
          tag.i(class: 'fa fa-fw fa-underline')
        end
        add_separator
        add_menu('bullet_list') do
          tag.i(class: 'fa fa-fw fa-list-ul')
        end
        add_separator
        add_menu('link') do
          tag.i(class: 'fa fa-fw fa-link')
        end
        add_menu('blockquote') do
          tag.i(class: 'fa fa-fw fa-quote-right')
        end
        add_menu('image', merged_options) do
          tag.i(class: 'fa fa-fw fa-image')
        end
        add_menu('hr', merged_options) do
          tag.i(class: 'fa fa-fw fa-minus')
        end
      end)

      concat(tag.div({
        data: { target: 'editor2-form.target' },
        class: 'border-top-0',
      }.deep_merge(options[:target] || {})))

      concat(tag.div({
        data: { target: 'editor2-form.source' },
        style: 'display: none',
      }.deep_merge(options[:soruce] || {})) do
        body
      end)
    end
  end

  private

  def add_menu(menu, options = {})
    concat(link_to('#',
      data: flatten_hash_from(
        action: 'editor2-form#handleMenu',
        target: 'editor2-form.menu',
        'menu-name': menu,
        'menu-option': options[menu.to_sym],
      ),
      class: 'btn btn-sm mr-1') do
        yield
      end)
  end

  def add_separator
    concat(tag.span(class: 'ProseMirror-menuseparator'))
  end

  def flatten_hash_from(hash)
    hash.compact.each_with_object({}) do |(key, value), memo|
      next flatten_hash_from(value).each do |k, v|
        memo["#{key}-#{k}".intern] = v
      end if value.is_a?(Hash)
      memo[key] = value
    end
  end
end