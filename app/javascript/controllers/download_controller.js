import { Controller } from "stimulus"
import ufo from '../helpers/ufo_app'

export default class extends Controller {
  execute(event) {
    const downloadUrl = this.data.get('url')
    if (this.hasTargetLink(downloadUrl)) {
      return
    }

    event.preventDefault()

    if(ufo.isApp()) {
      const fileSourceId = this.data.get('fileSourceId')
      const fileName = this.data.get('fileName')
      ufo.post("download", { post: 0, file: +fileSourceId, name: fileName });
    } else if (event.shiftKey || event.ctrlKey || event.metaKey) {
      window.open(downloadUrl, '_blank');
    } else {
      window.location.href = downloadUrl;
    }
  }

  hasTargetLink(downloadUrl) {
    const targetAnchor = event.target.closest('a')
    const targetUrl = targetAnchor ? targetAnchor.getAttribute('href') : undefined
    return (targetUrl && downloadUrl != targetUrl && this.element.contains(targetAnchor))
  }
}