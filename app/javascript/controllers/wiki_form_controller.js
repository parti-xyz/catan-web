import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'
import Noty from 'noty'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = [
    'bodyField', 'submitButton'
  ]

  submit(event) {
    this.bodyFieldTarget.value = this.editorController.serialize()

    let valid = true
    if (!this.bodyFieldTarget.value || this.bodyFieldTarget.value.length < 0) {
      new Noty({
        type: 'warning',
        text: '본문 내용이 비었어요. [확인]',
        timeout: 3000,
        modal: true,
      }).show()
      valid = false
    } else if (this.bodyFieldTarget.value.length > 1048576) {
      new Noty({
        type: 'warning',
        text: '내용에 담긴 글이 너무 길거나 이미지 등이 너무 큽니다. 글을 나누어 등록하거나 사진 업로드를 이용하세요. [확인]',
        timeout: 3000,
        modal: true,
      }).show()
      valid = false
    }
    if (this.editorController.hasDangerConflict()) {
      new Noty({
        type: 'warning',
        text: '회원님이 고친 내용을 다시 살펴봐 주세요. 회원님이 고친 내용마다 \'다시 붙여넣기\'나 \'취소\'를 반드시 선택해야 합니다. [확인]',
        timeout: 3000,
        modal: true,
      }).show()
      valid = false
    }

    if (valid == false) {
      event.preventDefault()
      setTimeout(function(){ this.submitButtonTargets.forEach(el => jQuery.rails.enableElement(el)) }.bind(this), 1000)
      return false
    }
  }

  get editorController() {
    return this.application.getControllerForElementAndIdentifier(this.element, "editor-form")
  }

  success(event) {
    let [data, status, xhr] = event.detail;
    if (xhr.response) {
      const temp = document.createElement('div')
      temp.innerHTML = xhr.response;

      this.element.parentNode.replaceChild(temp.firstChild, this.element)
    }
  }
}