import { Controller } from "stimulus"
import parseJSON from '../helpers/json_parse'
import fetchResponseCheck from '../helpers/fetch_check_response';

export default class extends Controller {
  static targets = ['template']

  connect() {
    if (!this.binded) {
      let options = parseJSON(this.data.get('options')).value
      jQuery(this.element).popover(Object.assign({}, options, {
        content: this.templateTarget.textContent,
        trigger: 'focus',
        html: true,
        sanitize: false,
        class: this.data.get('className'),
      })).on('shown.bs.popover', function () {
        var $popup = jQuery(this);
        jQuery($popup.data('bs.popover').tip).find('[data-dismiss="popover"]').click(function (e) {
          $popup.popover('hide');
        });
      })
      this.binded = true
    }
    setTimeout(() => {
      jQuery(this.element).popover('show')
      const tip = jQuery(this.element).data('bs.popover').tip
      if (tip) {
        tip.classList.add(this.data.get('className'))
      }
    }, 3000)
  }

  dispose(event) {
    jQuery(this.element).popover('dispose')
  }
}
