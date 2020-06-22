import { Controller } from 'stimulus'
import autosize from 'autosize'

export default class extends Controller {
  connect() {
    autosize(this.element)
  }

  updateView(event) {
    autosize.update(this.element)
  }
}