import { Controller } from 'stimulus'
import Sortable from 'sortablejs'
import { v4 as uuidv4 } from 'uuid'

import fetchResponseCheck from '../helpers/fetch_check_response'

export default class extends Controller {
  static targets = ['category', 'cardBody']

  connect() {
    this.sortable = Sortable.create(this.element, {
      group: 'sharedCategory',
      animation: 150,
      filter: '.js-no-sort',
      onEnd: this.itemEnd.bind(this),
      onStart: this.itemStart.bind(this),
    })
  }

  itemStart(event) {
    this.cardBodyTargets.forEach(cardBody => {
      cardBody.classList.add('collapse')
    })
  }

  itemEnd(event) {
    let id = event.item.dataset.id
    let data = new FormData()
    data.append("position", event.newIndex + 1)

    let headers = new window.Headers()
    const csrfToken = document.head.querySelector("[name='csrf-token']")
    if (csrfToken) { headers.append('X-CSRF-Token', csrfToken.content) }

    let requestId = uuidv4()
    document.dispatchEvent(new CustomEvent('category-move-submit-begin', {
      bubbles: true,
      detail: [requestId],
    }))

    fetch(this.data.get("url").replace(":id", id), {
      headers: headers,
      method: 'PATCH',
      credentials: 'same-origin',
      body: data
    }).then(fetchResponseCheck)
      .then(response => {
        if (!response) {
          document.dispatchEvent(new CustomEvent('category-move-submit-error', {
            bubbles: true,
            detail: [requestId],
          }))
          return
        }

        document.dispatchEvent(new CustomEvent('category-move-submit-end', {
          bubbles: true,
          detail: [requestId],
        }))
      })
      .catch(e => {
        document.dispatchEvent(new CustomEvent('category-move-submit-error', {
          bubbles: true,
          detail: [requestId],
        }))
      })

    this.cardBodyTargets.forEach(cardBody => {
      cardBody.classList.remove('collapse')
    })
  }
}