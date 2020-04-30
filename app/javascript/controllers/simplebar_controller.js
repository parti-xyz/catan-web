import { Controller } from "stimulus"
import SimpleBar from 'simplebar'
SimpleBar.removeObserver()

export default class extends Controller {
  connect() {
    if (!this.currentSimplebar) {
      this.currentSimplebar = new SimpleBar(this.element)
    }
    this.restoreScroll()
  }

  disconnect() {
    if (this.currentSimplebar) {
      this.lastScrollTop = this.currentSimplebar.getScrollElement().scrollTop
      this.currentSimplebar.unMount()
      this.currentSimplebar = null

      delete this.element.dataset.simplebar
    }
  }

  restoreScroll() {
    const scrollElement = this.currentSimplebar.getScrollElement()
    const lastScrollTopFromData = this.element.parentNode ? +this.element.parentNode.dataset.jsScrollPersistenceScrollTop : undefined
    const lastScrollTop = (lastScrollTopFromData ? lastScrollTopFromData : this.lastScrollTop)
    if (lastScrollTop) {
      scrollElement.scrollTop = lastScrollTop
    }
  }
}
