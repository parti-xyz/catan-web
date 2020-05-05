import { Controller } from "stimulus"
import PhotoSwipe from 'photoswipe';
import PhotoSwipeUI_Default from 'photoswipe/dist/photoswipe-ui-default'
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  static targets = ['item']

  open(event) {
    const items = this.itemTargets.map((el, index) => {
      const paramMap = new ParamMap(this, el)
      const item = {
        src: paramMap.get('url'),
        w: paramMap.get('width'),
        h: paramMap.get('height'),
        title: paramMap.get('title'),
      }
      if (paramMap.has('originalUrl')) {
        item['downloadURL'] = paramMap.get('originalUrl')
      }

      return item
    })

    var options = {
      index: +(new ParamMap(this, event.currentTarget).get('index')),
      history: false,
    }

    const pswpElement = document.querySelector('#pswp')
    new PhotoSwipe(pswpElement, PhotoSwipeUI_Default, items, options).init()
  }
}