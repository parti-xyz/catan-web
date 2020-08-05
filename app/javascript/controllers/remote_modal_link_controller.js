import { Controller } from "stimulus";
import { v4 as uuidv4 } from 'uuid'

export default class extends Controller {
  initialize() {
    this.url = this.data.get('url')
  }

  connect() {
    this.uuid = uuidv4()

    document.body.insertAdjacentHTML('beforeend', this.template())

    this.modal = document.getElementById(this.uuid)
  }

  disconnect() {
    if (this.modal) {
      this.modal.parentNode.removeChild(this.modal)
    }
  }

  open(event) {
    event.preventDefault()

    if (!this.modal) { return }

    const modalController = this.application.getControllerForElementAndIdentifier(
      this.modal,
      "modal"
    )
    if (modalController) {
      modalController.open(this.url)
    }
  }

  template() {
    return `
      <div id=${this.uuid} class="modal fade front-app-modal" tabindex="-1" role="dialog" aria-hidden="true" data-controller="modal">
        <div class="modal-dialog" role="document">
          <div class="modal-content" data-target="modal.content">
          </div>
        </div>
      </div>
    `
  }
}