import { Controller } from 'stimulus'
import Sortable from 'sortablejs'
import { v4 as uuidv4 } from 'uuid'

import { smartFetch } from '../helpers/smart_fetch'

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
    let body = new FormData()
    body.append("position", event.newIndex + 1)

    let requestId = uuidv4()
    document.dispatchEvent(new CustomEvent('category-move-submit-begin', {
      bubbles: true,
      detail: [requestId],
    }))

    smartFetch(this.data.get("url").replace(":id", id), {
      method: 'PATCH',
      body,
    }).then(response => {
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