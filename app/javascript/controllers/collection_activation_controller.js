import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['item']

  toggle(event) {
    const currentItem = event.currentTarget.closest(`[data-target~="${this.identifier}.item"]`)
    if (!currentItem || !this.element.contains(currentItem)) { return }

    this.itemTargets.forEach((el) => {
      el.classList.toggle("-active", currentItem == el)
    })
  }

  deactiveAll(event) {
    this.itemTargets.forEach((el) => {
      el.classList.remove("-active")
    })
  }
}
