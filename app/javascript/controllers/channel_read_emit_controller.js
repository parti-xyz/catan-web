import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    const event = new CustomEvent('channel-read', {
      bubbles: true,
      detail: {
        channelId: this.data.get('channelId'),
        channelHasUnread: this.data.get('channelHasUnread'),
        channelReadAt: this.data.get('channelReadAt'),
      },
    })
    this.element.dispatchEvent(event)
  }
}