import { Controller } from 'stimulus'

import ParamMap from '../helpers/param_map'
import fetchResponseCheck from '../helpers/fetch_check_response'
import Timer from '../helpers/timer'
export default class extends Controller {
  static targets = ['channel']

  initialize() {
    this.syncing = false
  }

  connect() {
    this.timer = new Timer(this.sync.bind(this), this.data.get("refreshInterval"))

    this.sync()
  }

  disconnect() {
    if (this.timer) {
      this.timer.stop()
      this.timer = null
    }
  }

  sync() {
    if (this.syncing) {
      return
    }
    this.syncing = true

    fetch(this.data.get('url'))
      .then(fetchResponseCheck)
      .then(response => {
        if (response) {
          return response.json()
        }
      }).then(json => {
        if (json) {
          json.forEach(item => {
            item.needToRead
              ? this.unread(item.id)
              : this.read(item.id)
          })
        }
      }).catch(e => {
        if (this.timer) {
          this.timer.stop()
        }
      }).finally(() => {
        this.syncing = false
      })
  }

  consume(event) {
    this.timer.reset(true)
  }

  unread(channelId) {
    this.findElements(channelId).forEach(el => {
      el.classList.add('-active')
    })
  }

  read(channelId) {
    this.findElements(channelId).forEach(el => {
      el.classList.remove('-active')
    })
  }

  findElements(channelId) {
    return this.channelTargets.filter(el => {
      const paramMap = new ParamMap(this, el)
      return channelId === +paramMap.get('channelId')
    })
  }
}


