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
        add_menu('hardbreak') do
          tag_svg('editors/menus/hardbreak')
        end
        add_menu('paragraph') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-paragraph')
        end
        add_menu('h1') do
          tag_svg('editors/menus/h1')
        end
        add_menu('h2') do
          tag_svg('editors/menus/h2')
        end
        add_menu('h3') do
          tag_svg('editors/menus/h3')
        end
        add_separator
        add_menu('bold') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-bold')
        end
        add_menu('italic') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-italic')
        end
        add_menu('strike') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-strikethrough')
        end
        add_menu('underline') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-underline')
        end
        add_separator
        add_menu('bullet_list') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-list-ul')
        end
        add_menu('ordered_list') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-list-ol')
        end
        add_menu('indent_increase') do
          tag_svg('editors/menus/indent_increase')
        end
        add_menu('indent_decrease') do
          tag_svg('editors/menus/indent_decrease')
        end
        add_separator
        add_menu('link') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-link')
        end
        add_menu('blockquote') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-quote-right')
        end
        add_menu('image', merged_options) do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-image')
        end
        add_menu('hr') do
          tag.i(class: 'fa fa-fw fa-fw-xs fa-minus')
        end
        add_separator
        add_menu('insert_table') do
          tag_svg('editors/menus/insert_table')
        end
        add_menu('add_table_column_before') do
          tag_svg('editors/menus/add_table_column_before')
        end
        add_menu('add_table_column_after') do
          tag_svg('editors/menus/add_table_column_after')
        end
        add_menu('remove_table_column') do
          tag_svg('editors/menus/remove_table_column')
        end
        add_menu('add_table_row_before') do
          tag_svg('editors/menus/add_table_row_before')
        end
        add_menu('add_table_row_after') do
          tag_svg('editors/menus/add_table_row_after')
        end
        add_menu('remove_table_row') do
          tag_svg('editors/menus/remove_table_row')
        end
        add_menu('merge_table_cells') do
          tag_svg('editors/menus/merge_table_cells')
        end
        add_menu('split_table_cell') do
          tag_svg('editors/menus/split_table_cell')
        end
        add_menu('toggle_table_header_column') do
          tag_svg('editors/menus/toggle_table_header_column')
        end
        add_menu('toggle_table_header_row') do
          tag_svg('editors/menus/toggle_table_header_row')
        end
        add_menu('delete_table') do
          tag_svg('editors/menus/delete_table')
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

  def tag_svg(name)
    tag.div(class: 'd-flex fa-fw fa-fw-xs fa-fw-svg') do
      partial_svg(name)
    end
  end

  def add_menu(menu, options = {})
    concat(link_to('#',
      data: flatten_hash_from(
        action: 'editor2-form#handleMenu',
        target: 'editor2-form.menu',
        'menu-name': menu,
        'menu-option': options[menu.to_sym],
      ),
      class: 'btn btn-sm',
      style: 'margin-right: .125rem; margin-top: .125rem; margin-bottom: .125rem; padding: 0.25rem;') do
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