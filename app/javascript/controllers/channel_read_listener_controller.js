import { Controller } from 'stimulus'
import 'waypoints/lib/noframework.waypoints'
import 'waypoints/lib/shortcuts/inview'

import scrollParent from '../helpers/scroll_parent'
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  static targets = ['channel']

  consume(event) {
    if (!event.detail.channelId || !event.detail.channelHasUnread || !event.detail.channelReadAt) {
      return
    }
    const channelId = +event.detail.channelId
    const channelReadAt = +event.detail.channelReadAt

    if (event.detail.channelHasUnread === 'true' || event.detail.channelHasUnread === true) {
      this.unread(channelId, channelReadAt)
    } else {
      this.read(channelId, channelReadAt)
    }
  }

  unread(channelId, channelReadAt) {
    this.findElements(channelId, channelReadAt).forEach(el => {
      new ParamMap(this, el).set('channelReadAt', channelReadAt)
      el.classList.add('-active')
    })
  }

  read(channelId, channelReadAt) {
    this.findElements(channelId, channelReadAt).forEach(el => {
      new ParamMap(this, el).set('channelReadAt', channelReadAt)
      el.classList.remove('-active')
    })
  }

  findElements(channelId, channelReadAt) {
    return this.channelTargets.filter(el => {
      const paramMap = new ParamMap(this, el)
      if (!paramMap.get('channelReadAt')) { return false }

      const previousChannelReadAt = +paramMap.get('channelReadAt')
      return ((!previousChannelReadAt || previousChannelReadAt < channelReadAt) && channelId === +paramMap.get('channelId'))
    })
  }
}


