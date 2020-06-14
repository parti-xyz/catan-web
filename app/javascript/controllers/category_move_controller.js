import { Controller } from 'stimulus'
import Sortable from 'sortablejs'
import { v4 as uuidv4 } from 'uuid'

import fetchResponseCheck from '../helpers/fetch_check_response'

export default class extends Controller {
  static targets = ['channel', 'noText']

  connect() {
    this.sortable = Sortable.create(this.element, {
      group: 'shared',
      animation: 150,
      filter: '.js-no-sort',
      onEnd: this.itemEnd.bind(this),
    })
  }

  itemEnd(event) {
    let values = [this.loadData(event)]

    if (event.to != this.element) {
      let sourceController = this.application.getControllerForElementAndIdentifier(event.to, this.identifier)
      values.push(sourceController.loadData(event))
    }

    this.submit(values)
  }

  loadData(event) {
    if (this.channelTargets.length <= 0) {
      this.noTextTarget.classList.remove('collapse')
      return {
        id: (this.data.get('categoryId') || 'null'),
        channels: []
      }
    }

    this.noTextTarget.classList.add('collapse')
    let result = this.channelTargets.reduce((array, channelTarget) => {
      array.push(channelTarget.dataset.id)
      return array
    }, [])

    return {
      id: (this.data.get('categoryId') || 'null'),
      channels: result
    }
  }

  submit(value) {
    let data = new FormData()
    data.append("positions", JSON.stringify(value))

    let headers = new window.Headers()
    const csrfToken = document.head.querySelector("[name='csrf-token']")
    if (csrfToken) { headers.append('X-CSRF-Token', csrfToken.content) }

    let requestId = uuidv4()
    const event = new CustomEvent('category-move-submit-begin', {
      bubbles: true,
      detail: [requestId],
    })
    document.dispatchEvent(event)

    fetch(this.data.get("url"), {
      headers: headers,
      method: 'PATCH',
      credentials: 'same-origin',
      body: data
    }).then(fetchResponseCheck)
      .then(response => {
        if (!response) {
          const event = new CustomEvent('category-move-submit-error', {
            bubbles: true,
            detail: [requestId],
          })
          document.dispatchEvent(event)
          return
        }

        const event = new CustomEvent('category-move-submit-end', {
          bubbles: true,
          detail: [requestId],
        })
        document.dispatchEvent(event)
      })
      .catch(e => {
        const event = new CustomEvent('category-move-submit-error', {
          bubbles: true,
          detail: [requestId],
        })
        document.dispatchEvent(event)
      })
  }
}