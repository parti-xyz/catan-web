import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['channel', 'menu', 'tip']

  toggle(event) {
    if (!this.hasMenuTarget) { return }

    if (this.hasChannelTarget) {
      this.menuTarget.classList.add('disabled')
      this.tipTarget.classList.remove('collapse')
    } else {
      this.menuTarget.classList.remove('disabled')
      this.tipTarget.classList.add('collapse')
    }
  }
}