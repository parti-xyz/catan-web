import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['content']

  toggle$(event) {
    event.preventDefault()
    this.toggle(event)
  }

  toggle(event) {
    this._apply()
  }

  show(event) {
    this.contentTarget.classList.add('show')
  }

  hide(event) {
    this.contentTarget.classList.remove('show')
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
