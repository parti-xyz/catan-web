import { Controller } from "stimulus"
import { smartFetch } from '../helpers/smart_fetch'

export default class extends Controller {
  connect() {
    if (!this.loaded) {
      this.load()

      if (this.data.has("refreshInterval")) {
        this.startRefreshing()
      }
    }

    let self = this
    if (this.data.has("disableRefreshJqueryEvent")) {
      jQuery(this.element).on(this.data.get("disableRefreshJqueryEvent"), (event) => {
        if (this.loaded) {
          self.disableRefresh()
        }
      })
    }

    if (this.data.has("enableRefreshJqueryEvent")) {
      jQuery(this.element).on(this.data.get("enableRefreshJqueryEvent"), (event) => {
        self.enableRefresh()
      })
    }

    this.loading = false
    this.enableRefresh()
  }

  disconnect() {
    if (this.refreshInterVal) {
      clearInterval(this.refreshInterVal)
    }

    if (this.data.has("disableRefreshJqueryEvent")) {
      jQuery(this.element).off(this.data.get("disableRefreshJqueryEvent"))
    }

    if (this.data.has("enableRefreshJqueryEvent")) {
      jQuery(this.element).off(this.data.get("enableRefreshJqueryEvent"))
    }
  }

  load(callback) {
    if (this.loading) {
      return
    }
    this.loading = true
    smartFetch(this.data.get('url'))
      .then(response => {
        if (response) {
          return response.text()
        }
      })
      .then(html => {
        this.loaded = true
        if (html && this.enableRefreshing) {
          if (this.html != html) {
            this.html = html

            this.element.dispatchEvent(new CustomEvent('content-loader:beforeLoaded', {
              bubbles: true,
            }))

            this.element.innerHTML = html

            this.element.dispatchEvent(new CustomEvent('content-loader:afterLoaded', {
              bubbles: true,
            }))
          }
        }
      })
      .catch(e => {
        this.loaded = true
        if (this.refreshInterVal) {
          clearInterval(this.refreshInterVal)
        }
      })
      .finally(() => {
        this.loading = false
        if (callback) { callback() }
      })
  }

  startRefreshing() {
    this.enableRefresh()
    this.refreshInterVal = setInterval(() => {
      if (this.enableRefreshing) {
        this.load()
      }
    }, this.data.get("refreshInterval"))
  }

  reload(event) {
    event.preventDefault()
    let oldEnableRefreshing = this.enableRefreshing
    this.enableRefresh()

    let currentInnerHTML = event.target.innerHTML
    if (event.target.dataset.disableWith) {
      event.target.innerHTML = event.target.dataset.disableWith
    }
    this.load(() => {
      event.target.innerHTML = currentInnerHTML
      this.enableRefreshing = oldEnableRefreshing
    })
  }

  enableRefresh() {
    this.enableRefreshing = true
  }

  disableRefresh() {
    this.enableRefreshing = false
  }

  get loaded() {
    return this.data.get("loaded") == 'true'
  }

  set loaded(value) {
    this.data.set("loaded", value)
  }
}
