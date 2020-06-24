import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['item']

  connect() {
    if (this.hasItemTarget) {
      const height = 200;
      let computed = window.getComputedStyle(this.element)
      this.element.style.paddingBottom = (parseInt(computed.getPropertyValue('padding-bottom'), 10) + height) + 'px'

      var rect = this.itemTarget.getBoundingClientRect()
      this.itemTarget.style.bottom = '1rem'
      this.itemTarget.style.left = rect.left + 'px'
      this.itemTarget.style.width = rect.width + 'px'
      this.itemTarget.style.position = 'fixed'
      this.itemTarget.style.overflow = 'auto'
      this.itemTarget.style.maxHeight = height + 'px'
    }
  }
}