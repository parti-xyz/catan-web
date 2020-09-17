import { Controller } from 'stimulus'
import store from 'store2';

export default class extends Controller {
  connect() {
    store.session.remove('list-nav-controller#env')
  }
}