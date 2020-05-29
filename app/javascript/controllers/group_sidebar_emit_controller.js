import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    const event = new CustomEvent('group-sidebar', {
      bubbles: true,
      detail: {
        channelId: this.data.get('channelId'),
        folderId: this.data.get('folderId'),
      },
    })
    this.element.dispatchEvent(event)
  }
}