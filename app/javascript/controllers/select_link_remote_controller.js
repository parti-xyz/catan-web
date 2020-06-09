import { Controller } from "stimulus"
import fillTemplate from 'es6-dynamic-template'
import ParamMap from '../helpers/param_map'
import fetchResponseCheck from '../helpers/fetch_check_response';

export default class extends Controller {
  go(event) {
    const urlTemplate = new ParamMap(this, event.currentTarget).get('urlTemplate')
    if (!urlTemplate) return

    const value = event.currentTarget.value || ''
    const url = fillTemplate(decodeURIComponent(urlTemplate), { value })
    fetch(url)
      .then(fetchResponseCheck)
      .then(response => {
        if (response) {
          return response.text()
        }
      })
      .then(html => {
        if (!html) {
          return
        }
        this.element.innerHTML = html
      })
  }
}