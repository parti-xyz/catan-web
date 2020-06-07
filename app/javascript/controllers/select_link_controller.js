import { Controller } from "stimulus"
import fillTemplate from 'es6-dynamic-template'
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  go(event) {
    const urlTemplate = new ParamMap(this, event.currentTarget).get('urlTemplate')
    if (!urlTemplate) return

    const value = event.currentTarget.value
    const url = value
      ? fillTemplate(decodeURIComponent(urlTemplate), { value })
      : urlTemplate

    Turbolinks.visit(url)
  }
}