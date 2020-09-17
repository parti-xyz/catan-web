import { Controller } from 'stimulus'
import { smartFetch } from '../helpers/smart_fetch'

export default class extends Controller {
  static targets = ['toggle', 'circle', 'menu']
  connect() {
    jQuery(this.element).on('show.bs.dropdown', this.handleShow.bind(this))
    jQuery(this.element).on('hide.bs.dropdown', this.handleHide.bind(this))

    this.menuTarget.style.display = ''
    jQuery(this.toggleTarget).dropdown()
    this.showAfterMixUp = false
  }

  disconnect() {
    jQuery(this.element).off('show.bs.dropdown', this.handleShow.bind(this))
    jQuery(this.element).off('hide.bs.dropdown', this.handleHide.bind(this))
    this.dispose()
  }

  handleHide(event) {
    if (event.clickEvent.target.closest('[data-message-dropdown-keep-open]')) {
      return false
    }
    return true;
  }

  handleShow(event) {
    if (!this.hasCircleTarget || !this.circleTarget.dataset.lastMessageId) return

    let body = new FormData()
    body.append("last_message_id", this.circleTarget.dataset.lastMessageId)

    smartFetch(this.data.get('url'), {
      method: 'PATCH',
      body,
    }).then(response => {
        if (response && response.ok && this.hasCircleTarget) {
          this.circleTarget.classList.add('collapse')
        }
      })
  }

  dispose(event) {
    if (this.element.classList.contains('show')) {
      this.showAfterMixUp = true
      this.element.classList.remove('show')
    }
    jQuery(this.toggleTarget).dropdown('dispose')
  }

  mixUp(event) {
    jQuery(this.toggleTarget).dropdown()
    if (this.showAfterMixUp) {
      jQuery(this.toggleTarget).dropdown('toggle')
      this.showAfterMixUp = false
    }
  }
}