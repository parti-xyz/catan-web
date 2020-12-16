import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['formContent', 'fakeTextarea', 'realTextarea', 'editorForm']

  open(event) {
    event.preventDefault()

    let mention = event.currentTarget.dataset.mention
    if (mention && this.editorController && !new RegExp('\\B\@' + mention + '\\B').test(this.editorController.serialize())) {
      this.editorController.insertText('@' + mention + ' ')
    }

    this.formContentTarget.classList.add('show')

    if (this.hasFakeTextareaTarget) {
      this.fakeTextareaTarget.classList.remove('show')
      this.fakeTextareaTarget.classList.add('hide')
    }
    this.realTextareaTarget.classList.remove('hide')
    this.realTextareaTarget.classList.add('show')

    this.editorController.focus()
  }

  get editorController() {
    return this.application.getControllerForElementAndIdentifier(this.editorFormTarget, "editor-form")
  }
}