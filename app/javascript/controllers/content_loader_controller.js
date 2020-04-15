import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "output" ]

  connect() {
    this.load()
  }

  load() {
    fetch(this.data.get('url'))
      .then(response => response.text())
      .then(html => {
        this.element.innerHTML = html
      })
  }
}
