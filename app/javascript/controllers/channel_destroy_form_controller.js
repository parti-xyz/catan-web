import { Controller } from 'stimulus'
import Noty from 'noty'

export default class extends Controller {
  static targets = ['message', 'confirm', 'submitButton']

  submit(evnet) {
    let valid = true
    if (!this.messageTarget.value || this.messageTarget.value.length < 0) {
      new Noty({
        type: 'warning',
        text: '채널 삭제 메시지가 비었습니다. [확인]',
        timeout: 3000,
        modal: true,
      }).show()

      this.messageTarget.classList.add('is-invalid')
      valid = false
    }

    if (this.confirmTarget.value != this.confirmTarget.dataset['slug']) {
      new Noty({
        type: 'warning',
        text: '삭제하는 이 채널의 주소를 정확히 넣어주세요. [확인]',
        timeout: 3000,
        modal: true,
      }).show()

      this.confirmTarget.classList.add('is-invalid')
      valid = false
    }

    if (valid == false) {
      event.preventDefault()
      setTimeout(function () { this.submitButtonTargets.forEach(el => jQuery.rails.enableElement(el)) }.bind(this), 1000)
      return false
    }
  }
}