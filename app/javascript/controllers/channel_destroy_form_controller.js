import { Controller } from 'stimulus'
import appNoty from '../helpers/app_noty'

export default class extends Controller {
  static targets = ['message', 'confirm', 'submitButton']

  submit(evnet) {
    let valid = true
    if (!this.messageTarget.value || this.messageTarget.value.length < 0) {
      appNoty('채널 삭제 메시지가 비었습니다.', 'warning', true)
      this.messageTarget.classList.add('is-invalid')
      valid = false
    }

    if (this.confirmTarget.value != this.confirmTarget.dataset['slug']) {
      appNoty('삭제하는 이 채널의 주소를 정확히 넣어주세요.', 'warning', true)
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