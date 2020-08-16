import { Controller } from 'stimulus'
import { smartFetch } from '../helpers/smart_fetch'

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

    let body = new FormData()
    body.append("label_id", labelId)

    smartFetch(this.data.get("url"), {
      method: 'PATCH',
      body,
    }).then(response => {
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

