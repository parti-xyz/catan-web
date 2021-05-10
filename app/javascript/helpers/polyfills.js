import 'whatwg-fetch'
import elementClosest from 'element-closest'
import 'array-from-polyfill'
import 'url-search-params-polyfill'
import Stickyfill from 'stickyfilljs'
import 'classlist-polyfill'
import supports from 'css-supports'

const polyfills = (window) => {
  elementClosest(window)
  if (window.NodeList && !NodeList.prototype.forEach) {
    NodeList.prototype.forEach = Array.prototype.forEach;
  }

  // remove() https://developer.mozilla.org/ko/docs/Web/API/ChildNode/remove
  (function (arr) {
    arr.forEach(function (item) {
      if (item.hasOwnProperty('remove')) {
        return;
      }
      Object.defineProperty(item, 'remove', {
        configurable: true,
        enumerable: true,
        writable: true,
        value: function remove() {
          if (this.parentNode !== null)
            this.parentNode.removeChild(this);
        }
      });
    });
  })([Element.prototype, CharacterData.prototype, DocumentType.prototype])

  if (!supports('position', 'sticky')) {
    window.addEventListener('DOMContentLoaded', (event) => {
      let elements = document.querySelectorAll('.js-polyfill-sticky')
      Stickyfill.add(elements)
    })
  }
}

Number.isNaN = Number.isNaN || function (value) {
  return value !== value;
}
export default polyfills

