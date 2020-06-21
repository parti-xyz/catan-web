import { Controller } from 'stimulus'
import ripplet from 'ripplet.js'

export default class extends Controller {
  static targets = ['item']
  run(event) {
    event.stopPropagation()
    this.itemTargets.forEach(item => {
      ripplet({ currentTarget: item }, { centered: true })
    })
  }
}