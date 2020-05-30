import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'
import serialize from '../helpers/serialize'

let throttle = require('lodash/throttle')

export default class extends Controller {
  static targets = ['menu', 'menuItem', 'folderMenuItem', 'menuItemText', 'searchScopeField', 'searchQueryField']

  initialize(){
    this.updateQueryField = throttle(this.updateQueryField, 200).bind(this)
  }

  connect() {
    this.updateQueryField()
  }

  upAndDownMenuItem(event) {
    if (this.menuTarget.style.display === 'none') {
      return
    }

    const currentActiveMenuItemElement = this.currentActiveMenuItem()
    let newActiveMenuItemElement = null

    const fistMenuItemElement = this.menuItemTargets[0]
    const lastMenuItemElement = this.menuItemTargets[this.menuItemTargets.length - 1]
    if (!currentActiveMenuItemElement) {
      newActiveMenuItemElement = fistMenuItemElement
    } else {
      switch (event.which) {
        case 38: // up
          newActiveMenuItemElement = this.cycle(this.menuItemTargets, currentActiveMenuItemElement, -1)
          break;
        case 40: // down
          newActiveMenuItemElement = this.cycle(this.menuItemTargets, currentActiveMenuItemElement, +1)
          break;
        default:
          break;
      }
      if (newActiveMenuItemElement) {
        this.toggleActiveMenuItem(newActiveMenuItemElement)
        event.preventDefault();
      }
    }
  }

  toggleActiveMenuItem(itemElement) {
    this.menuItemTargets.map(el => {
      el.classList.remove('-active')
    })
    itemElement.classList.add('-active')
  }

  cycle(array, item, to) {
    const i = array.indexOf(item)
    if (i === -1) return undefined
    return array[(i + to) % array.length];
  }

  updateQueryField(event) {
    const queryValue = this.searchQueryFieldTarget.value

    this.menuItemTextTargets.map(el => el.textContent = queryValue)
    if (!queryValue || queryValue.trim().length <= 0) {
      this.searchQueryFieldTarget.classList.add('-empty')
      if (event) { this.menuTarget.style.display = 'none' }
    } else {
      this.searchQueryFieldTarget.classList.remove('-empty')
      if (event) { this.menuTarget.style.display = 'block' }

      const currentActiveMenuItemElement = this.currentActiveMenuItem()
      if (!currentActiveMenuItemElement) {
        const fistMenuItemElement = this.menuItemTargets[0]
        this.toggleActiveMenuItem(fistMenuItemElement)
      }
    }
  }

  blurQueryField(event) {
    setTimeout(() => { this.menuTarget.style.display = 'none' }, 1000)
  }

  mouseEnterMenuItem(event) {
    this.toggleActiveMenuItem(event.currentTarget)
  }

  clickMenuItem(event) {
    event.preventDefault()

    const menuItem = event.currentTarget
    this.toggleActiveMenuItem(menuItem)

    this.submitForm(event)
  }

  submitForm(event) {
    event.preventDefault()

    const value = this.searchQueryFieldTarget.value
    if (!value || value.trim().length <= 0) {
      alert('찾을 단어를 입력하세요.')
      return
    }

    this.menuTarget.style.display = 'none'

    const currentActiveMenuItemElement = this.currentActiveMenuItem()
    const url = new ParamMap(this, currentActiveMenuItemElement).get('url')
    Turbolinks.visit(url + "?" + serialize(this.element))
  }

  currentActiveMenuItem() {
    return this.menuItemTargets.find(el => {
      return el.classList.contains('-active')
    })
  }
}
