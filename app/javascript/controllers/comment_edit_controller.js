import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'
import Noty from 'noty'
import Sortable from 'sortablejs'
import fetchResponseCheck from '../helpers/fetch_check_response'

export default class extends Controller {
  static targets = []

  loadForm(event) {
    event.preventDefault()

    if (this.data.get('form-url')) {
      fetch(this.data.get('form-url'))
        .then(fetchResponseCheck)
        .then(response => {
          if (response) {
            return response.text()
          }
        })
        .then(html => {
          if (html) {
            this.element.innerHTML = html
          }
        })
    }
  }
}