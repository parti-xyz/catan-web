import { Controller } from 'stimulus'
import { smartFetch } from '../../helpers/smart_fetch'

export default class extends Controller {
  connect() {
    this.disable = false
    Array.from(this.element.querySelectorAll("a[href]")).forEach(linkElement => {
      linkElement.addEventListener('click', this.handleClick.bind(this))
    })
  }

  disconnect() {
    Array.from(this.element.querySelectorAll("a[href]")).forEach(linkElement => {
      linkElement.removeEventListener('click', this.handleClick.bind(this))
    })
  }

  handleClick(event) {
    let messageUrl = event.currentTarget.getAttribute('href')
    if (!messageUrl) { return }

    event.preventDefault()

    if (this.disable) {
      return
    }
    this.disable = true

    return smartFetch(this.data.get('url'), {
      method: 'PATCH',
    }).then(response => {
      Turbolinks.visit(messageUrl)
    }).finally(() => {
      this.disable = false
    })
  }
}