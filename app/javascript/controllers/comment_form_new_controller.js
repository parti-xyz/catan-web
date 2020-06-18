import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['formContent', 'bodyField']

  open(event) {
    event.preventDefault()

    let oldValue = this.bodyFieldTarget.value || ''

    let mention = event.currentTarget.dataset.mention
    if (mention && !new RegExp('\\B\@' + mention + '\\B').test(oldValue)) {
      this.bodyFieldTarget.value = '@' + mention + ' ' + oldValue
    }

    this.formContentTarget.classList.add('show')
    this.bodyFieldTarget.focus()
  }
}