import { Controller } from "stimulus"
import fillTemplate from 'es6-dynamic-template'

export default class extends Controller {
  go(event) {
    const urlTemplate = this.data.get('urlTemplate')
    if (!urlTemplate) return

    const url = fillTemplate(decodeURIComponent(urlTemplate), { value: this.element.value })
    Turbolinks.visit(url)
  }
}