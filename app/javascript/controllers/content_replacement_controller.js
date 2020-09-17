import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['link']
  connect() {
    this.handleSuccessHandler = this.handleSuccess.bind(this)
    this.linkTargets.forEach(el => {
      el.addEventListener('ajax:success', this.handleSuccessHandler)
    })
  }

  disconnect() {
    if (this.handleSuccessHandler) {
      this.linkTargets.forEach(el => {
        el.removeEventListener('ajax:success', this.handleSuccessHandler)
      })
    }
  }

  handleSuccess(event) {
    const [data, status, xhr] = event.detail

    const temp = document.createElement('div')
    temp.innerHTML = xhr.response;

    this.element.parentNode.replaceChild(temp.firstChild, this.element)
  }
}


