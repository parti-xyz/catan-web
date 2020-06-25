import { Controller } from 'stimulus'
import fetchResponseCheck from '../helpers/fetch_check_response'

export default class extends Controller {
  static targets = ['toggle', 'circle', 'menu']
  connect() {
    jQuery(this.element).on('show.bs.dropdown', this.readAll.bind(this))

    this.menuTarget.style.display = ''
    jQuery(this.toggleTarget).dropdown()
    this.showAfterMixUp = false
  }

  disconnect() {
    jQuery(this.element).off('show.bs.dropdown', this.readAll.bind(this))
    this.dispose()
  }

  readAll(event) {
    if (!self.hasCircleTarget || !self.circleTarget.dataset.lastMessageId) return

    let headers = new window.Headers()
    const csrfToken = document.head.querySelector("[name='csrf-token']")
    if (csrfToken) { headers.append('X-CSRF-Token', csrfToken.content) }

    fetch(`${self.data.get('url')}?last_message_id=${self.circleTarget.dataset.lastMessageId}`, {
      headers: headers,
      method: 'PATCH',
      credentials: 'same-origin',
    })
      .then(fetchResponseCheck)
      .then(response => {
        if (response && response.ok && self.hasCircleTarget) {
          self.circleTarget.classList.add('collapse')
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