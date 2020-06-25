import { Controller } from 'stimulus'
import autosize from 'autosize'

export default class extends Controller {
  connect() {
    if (window.matchMedia && window.matchMedia("screen and (max-width: 450px)").matches) {
      jQuery(this.element).on('show.bs.dropdown', this.showDropDown.bind(this))
      jQuery(this.element).on('hide.bs.dropdown', this.hideDropDown.bind(this))
    }
  }

  disconnect() {
    jQuery(this.element).off('show.bs.dropdown', this.showDropDown.bind(this))
    jQuery(this.element).off('hide.bs.dropdown', this.hideDropDown.bind(this))
  }

  showDropDown(e) {
    jQuery(this.element).find('.dropdown-menu').first().stop(true, true).slideDown(200)
  }

  hideDropDown(e) {
    jQuery(this.element).find('.dropdown-menu').first().stop(true, true).slideUp(100)
  }
}



