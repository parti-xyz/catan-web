import { Controller } from 'stimulus'
import 'waypoints/lib/noframework.waypoints'
import 'waypoints/lib/shortcuts/inview'
import "velocity-animate/velocity.ui.min.js";

import scrollParent from '../helpers/scroll_parent'

export default class extends Controller {
  connect() {
    this.connected = false
    var self = this
    this.waypoint = new Waypoint.Inview({
      element: this.element,
      enter: function(direction) {
        if (this.connected) {
          self.toggleTargetElements()
        } else {
          this.connected = true
        }
      },
      exited: function(direction) {
        self.toggleTargetElements()
      },
      context: (scrollParent(this.element) || window),
    })
  }

  disconnect() {
    if (this.waypoint) {
      this.waypoint.destroy()
    }
  }

  findTargetElements() {
    return document.querySelectorAll(`[data-waypoint-toggler-target="${this.findToggleUid()}"]`)
  }

  findToggleUid() {
    return this.data.get('uid')
  }

  toggleTargetElements() {
    this.findTargetElements().forEach(el => {
      if (el.classList.contains('-active')) {
        el.classList.remove("-active")
      } else {
        el
          .velocity({
            opacity: 0
          }, {
            complete: () => {
              el.classList.add("-active")
            }
          }).velocity({
            opacity: 1
          }, {
            duration: 500
          })
      }
    })
  }
}


