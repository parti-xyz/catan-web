import { Controller } from 'stimulus'
import Turbolinks from "turbolinks"

export default class extends Controller {
  static targets = ['view']

  connect() {
    this.RequestQueue = []
  }

  startRequest(event) {
    event.stopPropagation()
    const [requestId] = event.detail
    this.RequestQueue.push(requestId)

    this.viewTarget.textContent = '저장 중...'
  }

  endRequest(event) {
    event.stopPropagation()
    const [requestId] = event.detail
    this.RequestQueue = this.RequestQueue.filter(queuedRequestId => queuedRequestId !== requestId)


    if (this.RequestQueue.length <= 0) {
      this.viewTarget.textContent = '저장 완료'
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
      this.viewTarget.textContent = '저장 실패'

      this.reloadPage()
    } else {
      this.error = true
    }
  }

  reloadPage() {
    Turbolinks.visit(window.location.toString(), { action: 'replace' })
  }
}