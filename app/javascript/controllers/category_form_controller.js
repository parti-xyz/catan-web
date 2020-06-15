import { Controller } from 'stimulus'
import appNoty from '../helpers/app_noty'

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
      appNoty('카테고리 제목이 비었어요.', 'warning', true)
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