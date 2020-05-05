import { Controller } from "stimulus"
import ufo from '../helpers/ufo_app'
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  static targets = ['modal', 'form', 'afterLogin', 'button']

  modal(event) {
    const modalController = this.application.getControllerForElementAndIdentifier(
      this.modalTarget,
      "modal"
    )
    if (modalController) {
      const afterLogin = new ParamMap(this, event.currentTarget).get('afterLogin')
      if (afterLogin) {
        this.afterLoginTarget.setAttribute('value', afterLogin)
      }
      const modalElement = modalController.open()
    }
  }

  auth(event) {
    this.buttonTargets.forEach(el => { el.setAttribute('disabled', true) })

    const paramMap = new ParamMap(this, event.currentTarget)
    const webUrl = paramMap.get('webUrl')
    const appUrl = paramMap.get('appUrl')

    if (ufo.isApp() && ufo.canHandle('startSocialSignIn') && appUrl) {
      window.location.href = appUrl;
    } else if (webUrl) {
      this.formTarget.setAttribute('action', webUrl)
      this.formTarget.submit()
    }
  }
}