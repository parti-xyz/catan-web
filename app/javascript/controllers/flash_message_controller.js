import { Controller } from 'stimulus'
import autosize from 'autosize'
import appNoty from '../helpers/app_noty'

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
    appNoty(flashMessage, type)
  }
}