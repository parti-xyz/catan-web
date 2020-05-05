import { Controller } from "stimulus"
import ufo from '../helpers/ufo_app'
import actionParams from '../helpers/action_params'

export default class extends Controller {
  static targets = ['modal', 'form', 'afterLogin', 'button']

  modal(event) {
    const modalController = this.application.getControllerForElementAndIdentifier(
      this.modalTarget,
      "modal"
    )
    if (modalController) {
      const { afterLogin } = actionParams(this, event.currentTarget)
      if (afterLogin) {
        this.afterLoginTarget.setAttribute('value', afterLogin)
      }
      const modalElement = modalController.open()
    }
  }

  auth(event) {
    this.buttonTargets.forEach(el => { el.setAttribute('disabled', true) })

    const webUrl = event.currentTarget.dataset.signInLauncherWebUrl
    const appUrl = event.currentTarget.dataset.signInLauncherAppUrl

    if (ufo.isApp() && ufo.canHandle('startSocialSignIn') && appUrl) {
      window.location.href = appUrl;
    } else if (webUrl) {
      this.formTarget.setAttribute('action', webUrl)
      this.formTarget.submit()
    }
  }
}