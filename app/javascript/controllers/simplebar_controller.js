import { Controller } from "stimulus"
import SimpleBar from 'simplebar'
SimpleBar.removeObserver()

import ParamMap from '../helpers/param_map'

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
    if (!scrollElement || scrollElement.scrollTop != 0) { return }

    const lastScrollTopFromData = this.element.parentNode ? +(new ParamMap(this, this.element.parentNode).get('persistedScrollTop')) : undefined
    const lastScrollTop = (lastScrollTopFromData ? lastScrollTopFromData : this.lastScrollTop)
    if (lastScrollTop) {
      scrollElement.scrollTop = lastScrollTop
    }
  }
}
