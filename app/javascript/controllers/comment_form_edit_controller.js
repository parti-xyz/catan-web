import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['viewContent', 'formContent', 'editorForm', 'bodyField']

  open(event) {
    event.preventDefault()

    this.viewContentTarget.classList.remove('show')
    this.formContentTarget.classList.add('show')

    if (this.editorController) {
      this.editorController.focus()
    } else if (this.hasBodyFieldTarget) {
      this.bodyFieldTarget.dispatchEvent(new CustomEvent('auto-resize:updateView', {
        bubbles: false,
      }))
      this.bodyFieldTarget.focus()
    }
  }

  get editorController() {
    return this.application.getControllerForElementAndIdentifier(this.editorFormTarget, "editor-form")
  }

  close(event) {
    event.preventDefault()

    this.viewContentTarget.classList.add('show')
    this.formContentTarget.classList.remove('show')
  }
}