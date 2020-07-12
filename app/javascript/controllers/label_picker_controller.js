import { Controller } from 'stimulus'
import fetchResponseCheck from '../helpers/fetch_check_response'

export default class extends Controller {
  static targets = ['preview', 'field', 'placeholder', 'loading']

  connect() {
    this.enable = true
  }

  disconnect() {
    this.enable = true
  }

  select(event) {
    let labelId = event.currentTarget.dataset.labelPickerId
    let labelTitle = event.currentTarget.dataset.labelPickerTitle

    this.change(labelId, labelTitle)
  }

  update(event) {
    let labelId = event.currentTarget.dataset.labelPickerId
    let labelTitle = event.currentTarget.dataset.labelPickerTitle

    if (!this.enable) {
      return
    }
    this.enable = false

    if (this.hasLoadingTarget) {
      this.previewTarget.classList.add('collapse')
      this.loadingTarget.classList.remove('collapse')
      this.placeholderTarget.classList.add('collapse')
    }

    let data = new FormData()
    data.append("label_id", labelId)

    let headers = new window.Headers()
    const csrfToken = document.head.querySelector("[name='csrf-token']")
    if (csrfToken) { headers.append('X-CSRF-Token', csrfToken.content) }


    let originEvent = event
    fetch(this.data.get("url"), {
      headers: headers,
      method: 'PATCH',
      credentials: 'same-origin',
      body: data
    }).then(fetchResponseCheck)
      .then(response => {
        this.change(labelId, labelTitle)
      })
      .finally(() => {
        this.enable = true
      })
  }

  change(labelId, labelTitle) {
    this.previewTarget.textContent = labelTitle
    if (labelTitle) {
      this.previewTarget.classList.remove('collapse')
      this.placeholderTarget.classList.add('collapse')
    } else {
      this.previewTarget.classList.add('collapse')
      this.placeholderTarget.classList.remove('collapse')
    }
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('collapse')
    }

    if (this.hasFieldTarget && labelId) {
      this.fieldTarget.value = labelId
    }
  }
}

