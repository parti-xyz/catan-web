import { Controller } from "stimulus"
import store from 'store2'

export default class extends Controller {
  static targets = ['content']

  toggle$(event) {
    event.preventDefault()
    this.toggle(event)
  }

  toggle(event) {
    this._apply()
  }

  _apply() {
    let style = window.getComputedStyle(this.contentTarget);

    if (style.display === 'none') {
      this.contentTarget.classList.add('show')
    } else {
      this.contentTarget.classList.remove('show')
    }
  }
}
