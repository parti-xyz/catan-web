import { Controller } from "stimulus"
import PhotoSwipe from 'photoswipe';
import PhotoSwipeUI_Default from 'photoswipe/dist/photoswipe-ui-default'

export default class extends Controller {
  static targets = ['item']

  open(event) {
    const items = this.itemTargets.map((el, index) => {
      const item = {
        src: el.dataset.url,
        w: el.dataset.width,
        h: el.dataset.height,
      }
      if (el.dataset.originalUrl) {
        item['downloadURL'] = el.dataset.originalUrl
      }

      return item
    })

    var options = {
      index: +event.currentTarget.dataset.index,
      history: false,
    }

    const pswpElement = document.querySelector('#pswp')
    new PhotoSwipe(pswpElement, PhotoSwipeUI_Default, items, options).init()
  }
}