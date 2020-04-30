import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    if (!this.loaded) {
      this.load()
    }
  }

  load() {
    fetch(this.data.get('url'))
      .then(response => response.text())
      .then(html => {
        this.loaded = true
        this.element.innerHTML = html
      })
  }

  get loaded() {
    return this.data.get("loaded") == 'true'
  }

  set loaded(value) {
    this.data.set("loaded", value)
  }
}
