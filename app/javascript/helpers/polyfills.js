import 'whatwg-fetch'
import elementClosest from 'element-closest'

const polyfills = (window) => {
  elementClosest(window)
  if (window.NodeList && !NodeList.prototype.forEach) {
    NodeList.prototype.forEach = Array.prototype.forEach;
  }
}
export default polyfills

