import { Controller } from 'stimulus'
import 'waypoints/lib/noframework.waypoints'
import 'waypoints/lib/shortcuts/inview'

import scrollParent from '../helpers/scroll_parent'

export default class extends Controller {
  connect() {
    const event = new CustomEvent('post-read', {
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