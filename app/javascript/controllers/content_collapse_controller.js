import { Controller } from "stimulus"
import store from 'store2'

export default class extends Controller {
  static targets = ['content']

  connect() {
    const force = this.data.get('force')
    if (force === 'show') {
      this.collapsed = false
    } else if (force === 'hide') {
      this.collapsed = true
    }
    this.data.delete('force')
    this._apply()
  }

  toggle$(event) {
    event.preventDefault()
    this.toggle(event)
  }

  toggle(event) {
    this.collapsed = !this.collapsed
    this._apply()
  }

  show(event) {
    this.collapsed = false
    this._apply()
  }

  hide(event) {
    this.collapsed = true
    this._apply()
  }

  _apply() {
    if (this.collapsed) {
      this.contentTargets.forEach(content => content.classList.remove('-show'))
      this.contentTargets.forEach(content => content.classList.add('-hide'))
    } else {
      this.contentTargets.forEach(content => content.classList.remove('-hide'))
      this.contentTargets.forEach(content => content.classList.add('-show'))
    }
  }

  get collapsed() {
    let storeCollapsed = (store.get(this.collapsedStoreKey) || {})
    if (storeCollapsed[this.id] === undefined) {
      const defaultCollapsed = true
      return defaultCollapsed
    }
    return storeCollapsed[this.id].valueOf()
  }

  set collapsed(value) {
    store.transact(this.collapsedStoreKey, data => {
      const result = (data || {})
      result[this.id] = new Boolean(!!value)

      return result
    })
  }

  get collapsedStoreKey() {
    return `${this.identifier}-controller#collapsed`
  }

  get id() {
    return this.data.get('id')
  }
}
