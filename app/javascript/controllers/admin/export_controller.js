import { Controller } from 'stimulus'
import { smartFetch } from '../../helpers/smart_fetch'

export default class extends Controller {
  static targets = ['status']

  submit(event) {
    event.preventDefault()

    smartFetch(this.element.getAttribute('action'), {
      method: 'POST',
      body: new FormData(this.element),
    }).then(response => {
      if (response) {
        return response.json()
      }
    }).then(json => {
      if (!json) {
        return
      }

      this.statusTarget.innerText = '파일 생성 중 0%...'

      let intervalName = `job_${json.jobId}`
      window[intervalName] = setInterval(() => {
        this.getExportStatus(json.jobId, intervalName, json.groupSlug)
      }, 800)
    })
  }

  getExportStatus(jobId, intervalName, groupSlug) {
    return smartFetch(this.data.get('statusUrl') + '?' + new URLSearchParams({
      job_id: jobId,
    }), {
      method: 'GET',
    }).then(response => {
      if (response) {
        return response.json()
      }
    }).then(json => {
      if (!json) {
        this.wrapUp('파일 생성 실패', intervalName)
        return
      }

      if (json.status == 'not-found') {
        this.wrapUp('파일 생성 실패', intervalName)
        return
      }

      this.statusTarget.innerText = `파일 생성 중 ${json.percentage || 0}%...`

      if (json.status === 'complete') {
        this.wrapUp('', intervalName, () => {
          window.location.href = this.data.get('downloadUrl') + '?' + new URLSearchParams({
            job_id: jobId,
            group_slug: groupSlug,
          })
        })
      }
    })
  }

  wrapUp(message, intervalName, callback) {
    setTimeout(() => {
      clearInterval(window[intervalName])
      delete window[intervalName]

      if (callback) {
        callback.bind(this).call()
      }

      this.statusTarget.innerText = message
      this.element.querySelectorAll('[data-disable-with]').forEach(disabledElement => {
        jQuery.rails.enableElement(disabledElement)
      })
    }, 500)
  }
}