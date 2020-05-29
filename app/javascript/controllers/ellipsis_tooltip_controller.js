import { Controller } from "stimulus"

export default class extends Controller {
  show(event) {
    const title = this.element.getAttribute('title')
    if (jQuery && this.element.offsetWidth < this.element.scrollWidth && !!title) {
      jQuery(this.element).tooltip({
        title: title,
        placement: "bottom"
      });
      jQuery(this.element).tooltip('show');
    }
  }
}
