import { Controller } from "stimulus"
import parseJSON from '../helpers/json_parse'

export default class extends Controller {
  click(event) {
    event.preventDefault()
    this.bind()
    this.show()
  }

  bind() {
    if(!this.binded) {
      let options = parseJSON(this.data.get('options')).value
      jQuery(this.element).popover(Object.assign({}, options, {
        content: this.content.bind(this),
        trigger: 'focus',
        html: true,
        sanitize: false,
        class: this.data.get('className'),
      }))
      this.binded = true
    }
  }

  show() {
    jQuery(this.element).popover('show')
    const tip = jQuery(this.element).data('bs.popover').tip
    if(tip) {
      tip.classList.add(this.data.get('className'))
    }
  }

  content() {
    if (this.html) { return this.html }

    fetch(this.data.get('url')).then(response => {
      return response.text()
    })
    .then(html => {
      this.html = html
      jQuery(this.element).data('bs.popover').setContent()
      jQuery(this.element).popover('update')
    })

    return this.loadingContent()
  }

  loadingContent() {
    return '<div><i class="fa fa-spinner fa-pulse fa-fw text-muted"></i></div>'
  }
}
