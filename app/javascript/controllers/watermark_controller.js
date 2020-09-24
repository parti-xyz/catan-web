import { Controller } from 'stimulus'
import autosize from 'autosize'

export default class extends Controller {
  connect() {
    let text = this.data.get('text')

    var svgstring = '<svg id="diagtext" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%" height="100%"><style type="text/css">text { fill: gray; font-family: Avenir, Arial, Helvetica, sans-serif; }</style><defs><pattern id="twitterhandle" patternUnits="userSpaceOnUse" width="100" height="50"><text y="30" font-size="10" id="name">' + text + '</text></pattern><pattern xlink:href="#twitterhandle"><text y="40" x="50" font-size="10" id="occupation">' + text + '</text></pattern><pattern id="combo" xlink:href="#twitterhandle" patternTransform="rotate(-45)"><use xlink:href="#name" /><use xlink:href="#occupation" /></pattern></defs><rect width="100%" height="100%" fill="url(#combo)" /></svg>'

    this.element.style.backgroundImage = "url('data:image/svg+xml;base64," + window.btoa(svgstring) + "')"
  }
}