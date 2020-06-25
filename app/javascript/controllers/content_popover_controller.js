import { Controller } from "stimulus"
import parseJSON from '../helpers/json_parse'
import fetchResponseCheck from '../helpers/fetch_check_response'
import { isTouchDevice } from '../helpers/device';

export default class extends Controller {
  connect() {
    if(!this.binded) {
      let tabIndex = this.element.getAttribute('tabindex')
      if (!tabIndex) {
        this.element.setAttribute('tabindex', '0')
      }

      let options = parseJSON(this.data.get('options')).value
      jQuery(this.element).popover(Object.assign({}, options, {
        content: this.content.bind(this),
        trigger: (isTouchDevice() ? 'focus' : 'focus hover'),
        html: true,
        sanitize: false,
        class: this.data.get('className'),
      }))
      this.binded = true
    }
  }

  disconnect() {
    jQuery(this.element).popover('dispose')
  }

  show() {
    jQuery(this.element).popover('show')

    let popover = jQuery(this.element).data('bs.popover')
    if (!popover) { return }

    const tip = popover.tip
    if(tip) {
      tip.classList.add(this.data.get('className'))
    }
  }

  content() {
    if (this.html) { return this.html }

    fetch(this.data.get('url'))
      .then(fetchResponseCheck)
      .then(response => {
        if (response) {
          return response.text()
        }
      })
      .then(html => {
        if (!html) {
          return
        }
        this.html = html

        let popover = jQuery(this.element).data('bs.popover')
        if (!popover) { return }
        popover.setContent()

        jQuery(this.element).popover('update')
      })

    return this.loadingContent()
  }

  loadingContent() {
    return '<div><i class="fa fa-spinner fa-pulse fa-fw text-muted"></i></div>'
  }
}
