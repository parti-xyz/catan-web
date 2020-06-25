import { Controller } from "stimulus"
import fetchResponseCheck from '../helpers/fetch_check_response'

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
        self.reload()
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

  load() {
    if (this.loading) {
      return
    }
    this.loading = true
    fetch(this.data.get('url'))
      .then(fetchResponseCheck)
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

  reload() {
    this.load()
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
