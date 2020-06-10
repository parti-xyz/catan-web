import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['form']

  submit(event) {
    let formUrl = event.currentTarget.dataset.formUrl
    this.formTarget.setAttribute('action', formUrl)
    this.formTarget.submit()
  }
}