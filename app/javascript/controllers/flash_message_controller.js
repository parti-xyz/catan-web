import { Controller } from 'stimulus'
import autosize from 'autosize'
import Noty from 'noty'

export default class extends Controller {
  connect() {
    const flashType = this.data.get('type')
    const flashMessage = this.data.get('message')

    let type = 'info'
    if (flashType == 'alert') {
      type = 'warning'
    } else if (flashType == 'notice') {
      type = 'success'
    }
    new Noty({
      type,
      text: flashMessage,
      timeout: 3000,
    }).show()
  }
}