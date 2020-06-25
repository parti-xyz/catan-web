import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['item', 'lines']

  connect() {
    if (this.hasItemTarget) {
      const height = 200;
      let computed = window.getComputedStyle(this.element)
      this.element.style.paddingBottom = (parseInt(computed.getPropertyValue('padding-bottom'), 10) + height) + 'px'

      var rect = this.itemTarget.getBoundingClientRect()
      this.itemTarget.style.bottom = '0'
      this.itemTarget.style.left = '0'
      this.itemTarget.style.width = '100%'
      this.itemTarget.style.position = 'fixed'
      this.itemTarget.style.borderLeft = 'none'
      this.itemTarget.style.borderRight = 'none'
      this.itemTarget.style.zIndex = 10

      this.linesTarget.style.maxHeight = '150px'
      this.linesTarget.style.overflow = 'auto'
    }
  }
}