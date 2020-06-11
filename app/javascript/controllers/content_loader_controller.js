import { Controller } from "stimulus"
import fetchResponseCheck from '../helpers/fetch_check_response';

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
        self.disableRefresh()
      })
    }

    if (this.data.has("enableRefreshJqueryEvent")) {
      jQuery(this.element).on(this.data.get("enableRefreshJqueryEvent"), (event) => {
        self.enableRefresh()
        self.reload()
      })
    }

    this.enableRefresh()
  }

  load() {
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
            this.element.innerHTML = html
          }
        }
      })
      .catch(e => {
        this.loaded = true
      })
  }

  startRefreshing() {
    this.enableRefresh()
    setInterval(() => {
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
