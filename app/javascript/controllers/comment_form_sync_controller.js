import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['commentsContent']

  update(event) {
    event.preventDefault()

    let [response, status, xhr] = event.detail
    this.commentsContentTarget.innerHTML = xhr.response
  }
}