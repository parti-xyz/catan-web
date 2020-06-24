import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['link']
  connect() {
    this.linkTargets.forEach(el => {
      el.addEventListener('ajax:success', this.handleSuccess.bind(this))
    })
  }

  disconnect() {
    this.linkTargets.forEach(el => {
      el.removeEventListener('ajax:success', this.handleSuccess.bind(this))
    })
  }

  handleSuccess(event) {
    if (!this.replaced) {
      this.replaced = true
      const [data, status, xhr] = event.detail

      const temp = document.createElement('div')
      temp.innerHTML = xhr.response;

      this.element.parentNode.replaceChild(temp.firstChild, this.element)
    }
  }
}


