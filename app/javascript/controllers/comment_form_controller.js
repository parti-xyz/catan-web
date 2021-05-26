import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'
import appNoty from '../helpers/app_noty'
import Sortable from 'sortablejs'

const MAX_FILE_COUNT = 20

export default class extends Controller {
  static targets = [
    'fileSourcesFieldGroup', 'imageFileSourcesContainer', 'docFileSourcesContainer', 'fileSourcesCounter', 'fileSourceFieldTemplate', 'imageFileSourcePreviewTemplate', 'docFileSourcePreviewTemplate', 'addFileSourceFieldButton',
    'submitControl', 'bodyField']

  connect() {
    this.sortable = Sortable.create(this.imageFileSourcesContainerTarget)

    this.fileSourceFieldTemplate = this.fileSourceFieldTemplateTarget.textContent
    this.imageFileSourcePreviewTemplate = this.imageFileSourcePreviewTemplateTarget.textContent
    this.docFileSourcePreviewTemplate = this.docFileSourcePreviewTemplateTarget.textContent

    this.fileSourceCounter()
  }

  submit(event) {
    let temp = document.createElement('div')
    if (this.editorController) {
      this.bodyFieldTarget.value = this.editorController.serialize()
      temp.innerHTML = this.bodyFieldTarget.value
    } else {
      temp.textContent = this.bodyFieldTarget.value
    }

    let valid = true
    if (!temp.textContent || temp.textContent.length <= 0) {
      appNoty('본문 내용이 비었어요.', 'warning', true).show()
      valid = false
    } else if (this.bodyFieldTarget.value.length > 1048576) {
      appNoty('내용에 담긴 글이 너무 길거나 이미지 등이 너무 큽니다. 글을 나누어 등록하거나 사진 업로드를 이용하세요.', 'warning', true).show()
      valid = false
    }

    this.element.dispatchEvent(new CustomEvent('dirty-form:submit', {
      bubbles: false,
    }))

    if (valid == false) {
      event.preventDefault()
      setTimeout(() => { jQuery.rails.enableElement(this.submitControlTarget) }, 1000)
      return false
    }
  }

  get editorController() {
    return this.application.getControllerForElementAndIdentifier(this.element, "editor2-form")
  }

  focusBodyField(event) {
    this.submitControlTarget.classList.add('btn-primary')
    this.submitControlTarget.classList.remove('btn-light')
  }

  blurBodyField(event) {
    const value = this.bodyFieldTarget.value
    if (value && value.length > 0) {
      this.submitControlTarget.classList.add('btn-primary')
      this.submitControlTarget.classList.remove('btn-light')
    } else {
      this.submitControlTarget.classList.remove('btn-primary')
      this.submitControlTarget.classList.add('btn-light')
    }
  }

  openFileSourcesFieldGroup(event) {
    event.preventDefault()
    this.fileSourcesFieldGroupTarget.classList.add('-active')
    this.addFileSourceField(event)
    this.fileSourcesFieldGroupTarget.scrollIntoView({
      behavior: 'smooth'
    })
  }

  closeFileSourcesFieldGroup(event) {
    if(this.activeFileSourceFieldsCount > 0 && !confirm('등록한 모든 파일을 업로드 취소하시겠습니까?')) {
      return;
    }
    event.preventDefault()

    this.activeFileSourceFields.forEach(fileSourceField => {
      this.removeFileSourceFieldElement(fileSourceField)
    })

    this.fileSourcesFieldGroupTarget.classList.remove('-active')
  }

  addFileSourceField(event) {
    event.preventDefault()

    if (event.currentTarget.hasAttribute('disabled')) {
      appNoty(`파일 ${MAX_FILE_COUNT}개까지만 업로드 가능합니다.`, 'warning', true).show()
      return
    }

    const content = this.fileSourceFieldTemplate.replace(/NEW_RECORD/g, new Date().getTime())
    this.element.insertAdjacentHTML('beforeend', content)

    const fileSourceField = this.element.lastElementChild
    fileSourceField.querySelector("input[type='file']").click()
  }

  removeFileSourceField(event) {
    event.preventDefault()

    const fileSourceField = event.currentTarget.closest(`[data-target~="${this.identifier}.fileSourceField"]`)

    this.removeFileSourceFieldElement(fileSourceField)
  }

  removeFileSourceFieldElement(fileSourceField) {
    if (!fileSourceField) {
      return
    }

    const paramMap = new ParamMap(this, fileSourceField)
    if (paramMap.get('newRecord') === 'true') {
      // New records are simply removed from the page
      fileSourceField.remove()
    } else {
      // Existing records are hidden and flagged for deletion
      fileSourceField.querySelector("input[name*='_destroy']").value = 1
      fileSourceField.classList.remove('-active')
      fileSourceField.classList.remove('-image')
      fileSourceField.classList.remove('-doc')
    }

    this.fileSourceCounter()
  }

  changeFileSourceField(event) {
    const fileField = event.currentTarget
    if (!fileField.files || !fileField.files[0]) {
      return
    }

    const currentFile = fileField.files[0]
    const fileSourceField = fileField.closest(`[data-target~="${this.identifier}.fileSourceField"]`)

    if (parseInt(fileField.dataset.ruleFilesize) < currentFile.size) {
      appNoty('10MB 이하의 파일만 업로드 가능합니다.', 'warning', true).show()
      fileSourceField.remove()
    } else {
      if (/^image/.test(currentFile.type) ) {
        const content = this.imageFileSourcePreviewTemplate.replace(/SRC/g, URL.createObjectURL(currentFile))
        fileSourceField.insertAdjacentHTML('beforeend', content)

        this.imageFileSourcesContainerTarget.appendChild(fileSourceField)
        this.imageFileSourcesContainerTarget.style.display = 'block'

        fileSourceField.classList.add('-image')
        fileSourceField.classList.remove('-doc')
      } else {
        const content = this.docFileSourcePreviewTemplate
          .replace(/NAME/g, currentFile.name)
          .replace(/SIZE/g, this.formatBytes(currentFile.size))
        fileSourceField.insertAdjacentHTML('beforeend', content)

        this.docFileSourcesContainerTarget.appendChild(fileSourceField)
        this.docFileSourcesContainerTarget.style.display = 'block'

        fileSourceField.classList.add('-doc')
        fileSourceField.classList.remove('-image')
      }
      fileSourceField.classList.add('-active')
    }
    this.fileSourceCounter()
  }

  formatBytes(bytes, decimals) {
    if (bytes == 0) return '0 Bytes';
    var k = 1000,
      dm = decimals + 1 || 3,
      sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
      i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  fileSourceCounter() {
    if (this.activeFileSourceFieldsCount >= MAX_FILE_COUNT) {
      this.addFileSourceFieldButtonTarget.classList.add('disabled')
      this.addFileSourceFieldButtonTarget.setAttribute("disabled", "")
    } else {
      this.addFileSourceFieldButtonTarget.classList.remove('disabled')
      this.addFileSourceFieldButtonTarget.removeAttribute("disabled")
    }

    this.fileSourcesCounterTarget.textContent = this.activeFileSourceFieldsCount
  }

  get activeFileSourceFieldsCount() {
    return this.activeFileSourceFields.length
  }

  get activeFileSourceFields() {
    const activeImageFileSources = this.imageFileSourcesContainerTarget.querySelectorAll(`.-active[data-target~="${this.identifier}.fileSourceField"]`)
    const activeDocFileSources = this.docFileSourcesContainerTarget.querySelectorAll(`.-active[data-target~="${this.identifier}.fileSourceField"]`)

    return [...activeImageFileSources, ...activeDocFileSources]
  }
}