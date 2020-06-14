import { Controller } from 'stimulus'
import Noty from 'noty'

export default class extends Controller {
  static targets = ['view', 'form', 'nameField', 'submitButton']

  show(event) {
    event.preventDefault()

    this.viewTarget.classList.add('collapse')
    this.formTarget.classList.remove('collapse')
  }

  hide(event) {
    this.viewTarget.classList.remove('collapse')
    this.formTarget.classList.add('collapse')

    if (this.hasFormTarget) {
      event.preventDefault()
      this.formTarget.reset()
    }
  }

  submit(event) {
    let valid = true

    if (!this.nameFieldTarget.value || this.nameFieldTarget.value.length <= 0) {
      new Noty({
        type: 'warning',
        text: '카테고리 제목이 비었어요. [확인]',
        timeout: 3000,
        modal: true,
      }).show()
      valid = false
    }

    if (valid == false) {
      event.preventDefault()
      setTimeout(function () { this.submitButtonTargets.forEach(el => jQuery.rails.enableElement(el)) }.bind(this), 1000)
      return false
    }

    return true
  }
}