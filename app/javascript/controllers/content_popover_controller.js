import { Controller } from "stimulus"
import parseJSON from '../helpers/json_parse'
import { smartFetch } from '../helpers/smart_fetch'
import { isTouchDevice } from '../helpers/device';

export default class extends Controller {
  connect() {
    if(!this.binded) {
      let tabIndex = this.element.getAttribute('tabindex')
      if (!tabIndex) {
        this.element.setAttribute('tabindex', '0')
      }

      let options = parseJSON(this.data.get('options')).value
      this.$popoverMe = jQuery(this.element).popover(Object.assign({}, options, {
        content: this.content.bind(this),
        trigger: (isTouchDevice() ? 'focus' : 'manual'),
        html: true,
        sanitize: false,
        class: this.data.get('className'),
        animation: false,
        placement: 'auto',
      }))

      this.$popoverMe.on("mouseenter", () => {
        setTimeout(() => {
          if (!this.$popoverMe) { return }
          if (window.__popover) { return }
          window.__popover = true

          this.$popoverMe.popover("show")
          jQuery(".popover").on("mouseleave", this.leave.bind(this))
        }, 500)
      }).on("mouseleave", () => {
        setTimeout(() => {
          if (!this.$popoverMe) { return }
          if (!jQuery(".popover:hover").length) {
            this.leave()
          }
        }, 100)
      })
      this.binded = true
    }
  }

  leave() {
    if (!this.$popoverMe) { return }

    this.$popoverMe.popover('hide')
    jQuery(".popover").off("mouseleave", this.leave.bind(this))
    window.__popover = false
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

    smartFetch(this.data.get('url'))
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
