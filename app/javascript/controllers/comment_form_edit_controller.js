import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['viewContent', 'formContent', 'editorForm']

  open(event) {
    event.preventDefault()

    this.viewContentTarget.classList.remove('show')
    this.formContentTarget.classList.add('show')

    this.editorController.focus()
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