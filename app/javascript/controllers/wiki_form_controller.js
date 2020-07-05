import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'
import appNoty from '../helpers/app_noty'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = [
    'bodyField', 'titleField', 'submitButton'
  ]

  submit(event) {
    this.bodyFieldTarget.value = this.editorController.serialize()

    let temp = document.createElement('div')
    temp.innerHTML = this.bodyFieldTarget.value

    let valid = true
    if (!temp.textContent || temp.textContent.length <= 0) {
      appNoty('본문 내용이 비었어요.', 'warning', true).show()
      valid = false
    } else if (this.bodyFieldTarget.value.length > 1048576) {
      appNoty('내용에 담긴 글이 너무 길거나 이미지 등이 너무 큽니다. 글을 나누어 등록하거나 사진 업로드를 이용하세요.', 'warning', true).show()
      valid = false
    }

    if (this.editorController.hasDangerConflict()) {
      appNoty('회원님이 고친 내용을 다시 살펴봐 주세요. 회원님이 고친 내용마다 \'다시 붙여넣기\'나 \'취소\'를 반드시 선택해야 합니다.', 'warning', true).show()
      valid = false
    }

    if(this.titleFieldTarget.value?.trim()?.length <= 0) {
      appNoty('제목을 넣어 주세요', 'warning', true).show()
      valid = false
    } else if (this.titleFieldTarget.value.length >= 120) {
      appNoty('제목이 너무 깁니다. 120자까지 가능합니다', 'warning', true).show()
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
    let [data, status, xhr] = event.detail

    if (xhr.getResponseHeader('X-Trubolinks-Redirect')) {
      return
    }

    if (xhr.response) {
      const temp = document.createElement('div')
      temp.innerHTML = xhr.response;

      this.element.parentNode.replaceChild(temp.firstChild, this.element)
    }
  }
}