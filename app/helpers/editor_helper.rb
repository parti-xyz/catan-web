module EditorHelper
  def editor(body)
    tag.div(data: { target: 'editor2-form.menuBarWrapper' }) do
      concat(tag.div(data: { target: 'editor2-form.menuBarSpacer' }))
      concat(tag.div(data: { target: 'editor2-form.menuBar' },
          class: 'p-1 border bg-white',
          style: 'z-index: 10') do |tag|
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
      end)
      concat(tag.div(data: { target: 'editor2-form.target' }, class: 'border-top-0'))
      concat(tag.div(data: { target: 'editor2-form.source' }, style: 'display: none') do
        body
      end)
    end
  end

  def add_menu(menu)
    concat(link_to('#',
      data: { action: 'editor2-form#handleMenu', target: 'editor2-form.menu', 'menu-name': menu },
      class: 'btn btn-sm mr-1') do
      yield
    end)
  end
end