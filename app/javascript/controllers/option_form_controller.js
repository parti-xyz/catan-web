import { Controller } from 'stimulus'
import autosize from 'autosize'

export default class extends Controller {
  static targets = ['bodyField']

  submit(event) {
    temp.innerHTML = this.bodyFieldTarget.value

    if (!this.bodyFieldTarget.value || this.bodyFieldTarget.value.length <= 0) {
      new Noty({
        type: 'warning',
        text: '제안 내용이 비었어요. [확인]',
        timeout: 3000,
        modal: true,
      }).show()
      valid = false
    } else if (this.bodyFieldTarget.value.length > 200) {
      new Noty({
        type: 'warning',
        text: '제안 내용이 너무 깁니다. [확인]',
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
  }
}