import { Controller } from 'stimulus'
import autosize from 'autosize'
import appNoty from '../helpers/app_noty'

export default class extends Controller {
  static targets = ['bodyField']

  submit(event) {
    if (!this.bodyFieldTarget.value || this.bodyFieldTarget.value.length <= 0) {
      appNoty('제안 내용이 비었어요.', 'warning', true).show()
      valid = false
    } else if (this.bodyFieldTarget.value.length > 200) {
      appNoty('제안 내용이 너무 깁니다. 200자까지 입력할 수 있습니다.', 'warning', true).show()
      valid = false
    }

    if (valid == false) {
      event.preventDefault()
      setTimeout(function () { this.submitButtonTargets.forEach(el => jQuery.rails.enableElement(el)) }.bind(this), 1000)
      return false
    }
  }
}