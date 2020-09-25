import { Controller } from 'stimulus'

import ParamMap from '../helpers/param_map'
import { smartFetch } from '../helpers/smart_fetch'
import Timer from '../helpers/timer'
export default class extends Controller {
  static targets = ['channel', 'needToNoticeCount', 'unreadMentionsCount', 'announcementsMenu', 'mentionsMenu']

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

    smartFetch(this.data.get('url'))
      .then(response => {
        if (response) {
          return response.json()
        }
      }).then(json => {
        if (json) {
          json.channels.forEach(item => {
            item.needToRead
              ? this.unread(item.id)
              : this.read(item.id)
          })

          if (this.hasNeedToNoticeCountTarget) {
            if (json.needToNoticeCount ) {
              this.needToNoticeCountTarget.classList.add('show')
              this.needToNoticeCountTarget.textContent = json.needToNoticeCount
            } else {
              this.needToNoticeCountTarget.classList.add('hide')
              this.needToNoticeCountTarget.textContent = ''
            }
          }
          this.announcementsMenuTarget.setAttribute('href', json.announcementsMenuUrl)

          if (this.hasUnreadMentionsCountTarget) {
            if (json.unreadMentionsCount) {
              this.unreadMentionsCountTarget.classList.add('show')
              this.unreadMentionsCountTarget.textContent = json.unreadMentionsCount
            } else {
              this.unreadMentionsCountTarget.classList.add('hide')
              this.unreadMentionsCountTarget.textContent = ''
            }
            this.mentionsMenuTarget.setAttribute('href', json.mentionsMenuUrl)
          }

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


