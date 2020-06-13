import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    const event = new CustomEvent('channel-read', {
      bubbles: true,
    })
    this.element.dispatchEvent(event)
  }
}