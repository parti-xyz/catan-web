import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'
import Noty from 'noty'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = [
    'bodyField',
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
    if (valid == false) {
      event.preventDefault()
    }
  }

  get editorController() {
    return this.application.getControllerForElementAndIdentifier(this.element, "editor-form")
  }
}