import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['formContent', 'fakeTextarea', 'realTextarea', 'editorForm', 'bodyField']

  open(event) {
    event.preventDefault()

    let mention = event.currentTarget.dataset.mention
    if (this.editorController) {
      this.openForEditor(mention)
    } else if (this.hasBodyFieldTarget) {
      this.openForTextarea(mention)
    }

    this.formContentTarget.classList.add('show')
  }

  openForEditor(mention) {
    if (mention && !new RegExp('\\B\@' + mention + '\\B').test(this.editorController.serialize())) {
      this.editorController.insertText('@' + mention + ' ')
    }
    this.editorController.focus()

    if (this.hasFakeTextareaTarget) {
      this.fakeTextareaTarget.classList.remove('show')
      this.fakeTextareaTarget.classList.add('hide')
    }
    if (this.hasRealTextareaTarget) {
      this.realTextareaTarget.classList.remove('hide')
      this.realTextareaTarget.classList.add('show')
    }
  }

  openForTextarea(mention) {
    let oldValue = this.bodyFieldTarget.value || ''
    if (mention && !new RegExp('\\B\@' + mention + '\\B').test(oldValue)) {
      this.bodyFieldTarget.value = '@' + mention + ' ' + oldValue
    }
    this.bodyFieldTarget.focus()
  }

  get editorController() {
    return this.application.getControllerForElementAndIdentifier(this.editorFormTarget, "editor2-form")
  }
}