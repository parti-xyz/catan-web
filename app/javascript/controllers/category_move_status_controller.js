import { Controller } from 'stimulus'
import Turbolinks from "turbolinks"

import appNoty from '../helpers/app_noty'

export default class extends Controller {
  static targets = ['view']

  connect() {
    this.RequestQueue = []
    this.noty = null
  }

  startRequest(event) {
    event.stopPropagation()
    const [requestId] = event.detail
    this.RequestQueue.push(requestId)

    let text = '저장 중... <i class="fa fa-spinner fa-pulse">'
    this.viewTarget.innerHTML = text

    this.ensureNoty(text, 'info', () => {
      if (!this.noty) { return }
      this.noty.resume()
    })
  }

  endRequest(event) {
    event.stopPropagation()
    const [requestId] = event.detail
    this.RequestQueue = this.RequestQueue.filter(queuedRequestId => queuedRequestId !== requestId)


    if (this.RequestQueue.length <= 0) {
      let text = '저장 완료'
      this.viewTarget.textContent = text
      this.ensureNoty(text, 'success', () => {
        if (!this.noty) { return }
        this.noty.resume()
      })
      if (this.error === true) {
        this.reloadPage()
      }
    }
  }

  errorRequest(event) {
    event.stopPropagation()
    const [requestId] = event.detail
    this.RequestQueue = this.RequestQueue.filter(queuedRequestId => queuedRequestId !== requestId)

    if (this.RequestQueue.length <= 0) {
      let text = '저장 실패'
      this.viewTarget.textContent = text
      this.ensureNoty(text, 'error', () => {
        if (!this.noty) { return }
        this.noty.start()
      })
      this.reloadPage()
    } else {
      this.error = true
    }
  }

  reloadPage() {
    Turbolinks.visit(window.location.toString(), { action: 'replace' })
  }

  ensureNoty(text, type, callback) {
    if (!this.noty) {
      this.noty = appNoty(text, type)
      this.noty.on('onClose', () => {
        this.noty = null
      }).on('onShow', callback)
      this.noty.show()
    } else {
      this.noty.setText(text)
      this.noty.setType(type)
      callback()
    }

    return this.noty
  }
}