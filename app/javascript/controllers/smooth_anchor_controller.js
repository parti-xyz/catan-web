import { Controller } from 'stimulus'
import scrollIntoView from 'scroll-into-view'

export default class extends Controller {
  go(event) {
    event.preventDefault()

    let target = document.querySelector(this.element.getAttribute('href'))
    if (!target) { return }

    scrollIntoView(target, {
      cancellable: true,
      align: {
        topOffset: 100,
      }
    }, (type) => {
      const event = new CustomEvent('ripple', {
        bubbles: true,
      })
      target.dispatchEvent(event)
    })
  }
}