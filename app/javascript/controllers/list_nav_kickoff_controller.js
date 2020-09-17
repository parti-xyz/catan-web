import { Controller } from 'stimulus'
import store from 'store2';
import Turbolinks from "turbolinks"

export default class extends Controller {
  store(event) {
    let postId = event.currentTarget.dataset.listNavKickoffPostId
    let payload = {
      validListReferrer: window.location.href,
      validPostId: postId,
    }
    store.session.set('list-nav-controller#env', payload)
  }
}