import { Controller } from "stimulus"
import Select2 from "select2"
import fillTemplate from 'es6-dynamic-template'
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  connect() {
    jQuery(this.element).select2({
      width: '100%',
      templateResult: (node) => {
        if(!node.element) {return}
        var $result = jQuery('<span style="display: flex; flex-wrap: nowrap"><span style="flex: none; width:' + (20 * +node.element.dataset.depth) + 'px;"></span><span style="flex:1">' + node.text + '</span></span>')

        return $result
      },
    })

    jQuery(this.element).on('select2:select', this.go.bind(this))
  }

  disconnect() {
    jQuery(this.element).select2('destroy')
  }

  go(event) {
    console.log(event)

    const urlTemplate = new ParamMap(this, event.currentTarget).get('urlTemplate')
    if (!urlTemplate) return

    const value = event.currentTarget.value
    const url = value
      ? fillTemplate(decodeURIComponent(urlTemplate), { value })
      : urlTemplate

    Turbolinks.visit(url)
  }
}