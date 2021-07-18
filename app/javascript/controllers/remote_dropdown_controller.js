import { Controller } from 'stimulus'
import { smartFetch } from '../helpers/smart_fetch'

export default class extends Controller {
  static targets = ['toggle', 'spinner', 'item', 'menu']
  connect() {
    jQuery(this.element).on('show.bs.dropdown', this.handleShow.bind(this))
    jQuery(this.element).on('hide.bs.dropdown', this.handleHide.bind(this))
    jQuery(this.toggleTarget).dropdown()
    this.loading = false

    if (this.hasSpinnerTarget) {
      this.spinnerHTML = this.spinnerTarget.outerHTML
    }
  }

  disconnect() {
    jQuery(this.element).off('show.bs.dropdown', this.handleShow.bind(this))
    jQuery(this.element).off('hide.bs.dropdown', this.handleHide.bind(this))
    jQuery(this.toggleTarget).dropdown('dispose')
    this.loading = false
  }

  handleHide(event) {
    if (event.clickEvent && event.clickEvent.target.closest('[data-message--dropdown-keep-open]')) {
      return false
    }
    return true;
  }

  handleShow(event) {
    if (this.loading) {
      return
    }
    this.loading = true

    if (this.hasItemTarget) {
      this.itemTargets.forEach(item => { item.remove() })
    }
    if (!this.hasSpinnerTarget && this.spinnerHTML) {
      this.menuTarget.insertAdjacentHTML('beforeend', this.spinnerHTML)
    }

    smartFetch(this.data.get('url'))
      .then(response => {
        if (response) {
          return response.text()
        }
      })
      .then(html => {
        this.menuTarget.insertAdjacentHTML('beforeend', html)
      })
      .catch(e => {
        jQuery(this.toggleTarget).dropdown('hide')
      })
      .finally(() => {
        if (this.hasSpinnerTarget) {
          this.spinnerTarget.remove()
        }
        this.loading = false
      })
  }
}