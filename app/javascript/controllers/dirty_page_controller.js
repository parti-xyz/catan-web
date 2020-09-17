import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['form']

  connect() {
    this.alerted = false

    this.preventLeavingHandler = this.preventLeaving.bind(this)
    document.addEventListener('beforeunload', this.preventLeavingHandler)

    this.preventVisitingHandler = this.preventVisiting.bind(this)
    document.addEventListener("turbolinks:before-visit", this.preventVisitingHandler)
  }

  disconnect() {
    if (this.preventLeavingHandler) {
      document.removeEventListener('beforeunload', this.preventLeavingHandler)
    }
    if (this.preventVisitingHandler) {
      document.removeEventListener("turbolinks:before-visit", this.preventVisitingHandler)
    }

    if (!this.alerted && this.anyDirtyForm()) {
      alert('저장되지 않은 변경사항이 있습니다.')
    }
    this.alerted = false
  }

  preventLeaving(event) {
    if (!this.alerted && this.anyDirtyForm()) {
      event.preventDefault()
      event.returnValue = '페이지를 이동하시겠습니까? 변경사항이 저장되지 않을 수 있습니다.'
      this.alerted = true
    }
  }

  preventVisiting(event) {
    if (!this.alerted && this.anyDirtyForm()) {
      if (!confirm('페이지를 이동하시겠습니까? 변경사항이 저장되지 않을 수 있습니다.')) {
        event.preventDefault()
        return
      }
      this.alerted = true
    }
  }

  anyDirtyForm() {
    if (!this.hasFormTarget) { return }

    return this.formTargets.some(form => {
      return form.dataset.dirtyFormIsDirty != 'false'
    })
  }
}




