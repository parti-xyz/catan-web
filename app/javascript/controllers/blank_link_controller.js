import { Controller } from 'stimulus'
import autosize from 'autosize'

export default class extends Controller {
  open(event) {
    const url = this.element.dataset.blankLinkUrl
    if (!url) return

    window.open(url, '_blank')
  }
}