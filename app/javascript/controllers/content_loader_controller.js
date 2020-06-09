import { Controller } from "stimulus"
import fetchResponseCheck from '../helpers/fetch_check_response';

export default class extends Controller {
  connect() {
    if (!this.loaded) {
      this.load()
    }
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
        if (html) {
          this.element.innerHTML = html
        }
      })
  }

  get loaded() {
    return this.data.get("loaded") == 'true'
  }

  set loaded(value) {
    this.data.set("loaded", value)
  }
}
