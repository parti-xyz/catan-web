import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['item']

  pick(event) {
    this.itemTargets.forEach((el) => {
      el.classList.toggle("-active", event.currentTarget == el)
    })
  }
}
