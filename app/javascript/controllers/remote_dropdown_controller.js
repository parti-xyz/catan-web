import { Controller } from 'stimulus'
import { smartFetch } from '../helpers/smart_fetch'

export default class extends Controller {
  static targets = ['toggle', 'spinner', 'item', 'menu']

  initialize() {
    this.element[`${this.identifier}-controller`] = this
  }

  connect() {
    jQuery(this.element).on('show.bs.dropdown', this.handleShow.bind(this))
    jQuery(this.element).on('hide.bs.dropdown', this.handleHide.bind(this))
    if (this.hasToggleTarget) {
      jQuery(this.toggleTarget).dropdown()
    }
    this.loading = false

    if (this.hasSpinnerTarget) {
      this.spinnerHTML = this.spinnerTarget.outerHTML
    }

    this.url = this.data.get('url')
  }

  disconnect() {
    jQuery(this.element).off('show.bs.dropdown', this.handleShow.bind(this))
    jQuery(this.element).off('hide.bs.dropdown', this.handleHide.bind(this))
    if (this.hasToggleTarget) {
      jQuery(this.toggleTarget).dropdown('dispose')
    }
    this.loading = false
  }

  handleHide(event) {
    if (event.clickEvent && event.clickEvent.target.closest('[data-message--dropdown-keep-open]')) {
      return false
    }
    return true;
  }

  handleShow(event) {
    if (!this.url) {
      return
    }
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

    let currentUrl = this.url

    smartFetch(currentUrl)
      .then(response => {
        if (response) {
          return response.text()
        }
      })
      .then(html => {
        this.menuTarget.insertAdjacentHTML('beforeend', html)

        if (this.url != currentUrl) {
          handleShow(event)
        }
      })
      .catch(e => {
        if (this.hasToggleTarget) {
          jQuery(this.toggleTarget).dropdown('hide')
        }
      })
      .finally(() => {
        if (this.hasSpinnerTarget) {
          this.spinnerTarget.remove()
        }
        this.loading = false
      })
  }

  changeUrl(url) {
    this.url = url
  }
}