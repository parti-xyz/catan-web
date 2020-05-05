export default class ParamMap {
  constructor({ identifier }, element) {
    this.identifier = identifier
    this.element = element
  }

  get(key) {
    const formattedKey = this.getFormattedKey(key)
    return this.element.getAttribute(formattedKey)
  }

  set(key, value) {
    const formattedKey = this.getFormattedKey(key)
    this.element.setAttribute(formattedKey, value)
    return this.get(key)
  }

  has(key) {
    const formattedKey = this.getFormattedKey(key)
    return this.element.hasAttribute(formattedKey)
  }

  delete(key) {
    if (this.has(key)) {
      const formattedKey = this.getFormattedKey(key)
      this.element.removeAttribute(formattedKey)
      return true
    } else {
      return false
    }
  }

  getFormattedKey(key) {
    return `data-${this.identifier}-${this.dasherize(key)}`
  }

  dasherize(value) {
    return value.replace(/([A-Z])/g, (_, char) => `-${char.toLowerCase()}`)
  }
}