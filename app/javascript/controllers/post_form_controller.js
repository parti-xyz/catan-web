import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'
import Noty from 'noty'
import Sortable from 'sortablejs'

const MAX_FILE_COUNT = 20

export default class extends Controller {
  static targets = ['fileSourcesFieldGroup', 'imageFileSourcesContainer', 'docFileSourcesContainer', 'fileSourcesCounter', 'fileSourceFieldTemplate', 'imageFileSourcePreviewTemplate', 'docFileSourcePreviewTemplate', 'addFileSourceFieldButton', 'bodyField']

  connect() {
    this.sortable = Sortable.create(this.imageFileSourcesContainerTarget)

    this.fileSourceFieldTemplate = this.fileSourceFieldTemplateTarget.textContent
    this.imageFileSourcePreviewTemplate = this.imageFileSourcePreviewTemplateTarget.textContent
    this.docFileSourcePreviewTemplate = this.docFileSourcePreviewTemplateTarget.textContent
  }

  openFileSourcesFieldGroup(event) {
    event.preventDefault()
    this.fileSourcesFieldGroupTarget.style.display = 'block'
    this.addFileSourceField(event)
  }

  closeFileSourcesFieldGroup(event) {
    if(this.activeFileSourcesCount > 0 && !confirm('등록한 모든 파일을 업로드 취소하시겠습니까?')) {
      return;
    }
    event.preventDefault()

    this.imageFileSourcesContainerTarget.innerHTML = ""
    this.docFileSourcesContainerTarget.innerHtml = ""

    this.fileSourcesFieldGroupTarget.style.display = 'none'
  }

  addFileSourceField(event) {
    event.preventDefault()

    if (event.currentTarget.hasAttribute('disabled')) {
      new Noty({
        type: 'warning',
        text: `파일 ${MAX_FILE_COUNT}개까지만 업로드 가능합니다. [확인]`,
        timeout: 3000,
        modal: true,
      }).show()

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
  }

  changeFileSourceField(event) {
    const fileField = event.currentTarget
    if (!fileField.files || !fileField.files[0]) {
      return
    }

    const currentFile = fileField.files[0]
    const fileSourceField = fileField.closest(`[data-target~="${this.identifier}.fileSourceField"]`)

    if (parseInt(fileField.dataset['rule-filesize']) < currentFile.size) {
      new Noty({
        type: 'warning',
        text: '10MB 이하의 파일만 업로드 가능합니다. [확인]',
        timeout: 3000,
        modal: true,
      }).show()
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
    this.counter()
  }

  submit(event) {
    this.editorController.serialize()

    if (!this.bodyFieldTarget.value || this.bodyFieldTarget.value.length < 0) {
      event.preventDefault()
      new Noty({
        type: 'warning',
        text: '본문 내용이 비었어요. [확인]',
        timeout: 3000,
        modal: true,
      }).show()
    }
  }

  get editorController() {
    return this.application.getControllerForElementAndIdentifier(this.element, "editor-form")
  }

  formatBytes(bytes, decimals) {
    if (bytes == 0) return '0 Bytes';
    var k = 1000,
      dm = decimals + 1 || 3,
      sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
      i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  counter() {
    if (this.activeFileSourcesCount >= MAX_FILE_COUNT) {
      this.addFileSourceFieldButtonTarget.classList.add('disabled')
      this.addFileSourceFieldButtonTarget.setAttribute("disabled", "")
    } else {
      this.addFileSourceFieldButtonTarget.classList.remove('disabled')
      this.addFileSourceFieldButtonTarget.removeAttribute("disabled")
    }

    this.fileSourcesCounterTarget.textContent = this.activeFileSourcesCount
  }

  get activeFileSourcesCount() {
    const activeImageFileSources = this.imageFileSourcesContainerTarget.querySelectorAll(`.-active[data-target~="${this.identifier}.fileSourceField"]`)
    const activeDocFileSources = this.docFileSourcesContainerTarget.querySelectorAll(`.-active[data-target~="${this.identifier}.fileSourceField"]`)

    const activeFileSourcesCount = [...activeImageFileSources, ...activeDocFileSources]

    return activeFileSourcesCount.length
  }
}