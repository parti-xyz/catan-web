import { Controller } from 'stimulus'
import autosize from 'autosize'
import appNoty from '../helpers/app_noty'

export default class extends Controller {
  static targets = ['baseTitleField', 'submitButton', 'cancelButton']

  submit(event) {
    if (event.target == this.cancelButtonTarget) { return }
    let valid = true

    if (this.baseTitleFieldTarget.value?.trim()?.length <= 0) {
      appNoty('제목을 넣어 주세요', 'warning', true).show()
      valid = false
    } else if (this.baseTitleFieldTarget.value.length >= 120) {
      appNoty('제목이 너무 깁니다. 120자까지 가능합니다', 'warning', true).show()
      valid = false
    }

    if (valid == false) {
      event.preventDefault()
      setTimeout(function () { this.submitButtonTargets.forEach(el => jQuery.rails.enableElement(el)) }.bind(this), 1000)
      return false
    }
  }
}