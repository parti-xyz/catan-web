import { Controller } from 'stimulus'
import fetchResponseCheck from '../helpers/fetch_check_response';

export default class extends Controller {
  static targets = ['circle']
  connect() {
    let self = this

    jQuery(this.element).on('show.bs.dropdown', (event) => {
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
    })
  }
}