import { Controller } from "stimulus"
import SimpleBar from 'simplebar'

export default class extends Controller {
  connect() {
    if (!this.currentSimplebar) {
      this.currentSimplebar = new SimpleBar(this.element)
    }
  }

  disconnect() {
    if (this.currentSimplebar) {
      this.currentSimplebar.unMount()
      this.currentSimplebar = new SimpleBar(this.element)
    }
  }

  reinit() {
    if (!this.currentSimplebar) {
      new SimpleBar(this.element)
    } else {
      this.currentSimplebar.init()
    }
  }

  elementSimplebar() {
    SimpleBar.instances.get(this.element)
  }
}
