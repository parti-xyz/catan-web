import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['form']

  connect() {
    document.addEventListener('beforeunload', this.preventLeaving.bind(this))
    document.addEventListener("turbolinks:before-visit", this.preventVisiting.bind(this))
  }

  disconnect() {
    document.removeEventListener('beforeunload', this.preventLeaving.bind(this))
    document.removeEventListener("turbolinks:before-visit", this.preventVisiting.bind(this))

    if (this.anyDirtyForm()) {
      alert('저장되지 않은 변경사항이 있습니다. 이전 페이지로 이동해 주세요.')
    }
  }

  preventLeaving(event) {
    if (this.anyDirtyForm()) {
      event.preventDefault()
      event.returnValue = '페이지를 이동하시겠습니까? 변경사항이 저장되지 않을 수 있습니다.'
    }
  }

  preventVisiting(event) {
    if (this.anyDirtyForm()) {
      if (!confirm('페이지를 이동하시겠습니까? 변경사항이 저장되지 않을 수 있습니다.')) {
        event.preventDefault()
      }
    }
  }

  anyDirtyForm() {
    if (!this.hasFormTarget) { return }

    return this.formTargets.some(form => {
      return form.dataset.dirtyFormIsDirty != 'false'
    })
  }
}




