import { Controller } from 'stimulus'
import { smartFetch } from '../../helpers/smart_fetch'

export default class extends Controller {
  connect() {
    Array.from(this.element.querySelectorAll("a[href]")).forEach(linkElement => {
      linkElement.addEventListener('click', event => {
        let messageUrl = event.currentTarget.getAttribute('href')
        if (!messageUrl) { return }

        return smartFetch(this.data.get('url'), {
          method: 'PATCH',
        }).then(response => {
            window.location = messageUrl
          })

        event.preventDefault()
      })
    })
  }
}