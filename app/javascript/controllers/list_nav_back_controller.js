import { Controller } from 'stimulus'
import store from 'store2';
import Turbolinks from "turbolinks"

export default class extends Controller {
  connect() {
    let env = store.session.get('list-nav-controller#env')
    if (!env || !env['validListReferrer']) {
      return
    }

    if (this.valid(env)) {
      this.element.setAttribute('href', env['validListReferrer'])
    }
  }

  valid(env) {
    return (Turbolinks.controller.currentVisit && env['validListReferrer'] === Turbolinks.controller.currentVisit.referrer.absoluteURL) || this.data.get('postId') === env['validPostId']
  }
}