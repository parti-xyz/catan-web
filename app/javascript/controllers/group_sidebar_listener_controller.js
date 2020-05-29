import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  static targets = ['channelActivation', 'channelCollapse', 'folderActivation', 'folderCollapse']

  consume(event) {
    if (!event.detail.channelId) {
      return
    }
    const channelId = +event.detail.channelId
    let folderId = event.detail.folderId
    if (folderId) {
      folderId = +folderId
    }

    if (!folderId) {
      const channelActivation = this.findElement(this.channelActivationTargets, 'channelId', channelId)
      if (channelActivation) {
        const event = new CustomEvent('group-sidebar-activation', {
          bubbles: false
        })
        channelActivation.dispatchEvent(event)
      }
    } else {
      const folderActivation = this.findElement(this.folderActivationTargets, 'folderId', folderId)
      if (folderActivation) {
        const event = new CustomEvent('group-sidebar-activation', {
          bubbles: false
        })
        folderActivation.dispatchEvent(event)
      }
    }

    const channelCollapse = this.findElement(this.channelCollapseTargets, 'channelId', channelId)
    if (channelCollapse) {
      const event = new CustomEvent('group-sidebar-collapse-show', {
        bubbles: false
      })
      channelCollapse.dispatchEvent(event)
    }
    if (folderId) {
      const folderCollapse = this.findElement(this.folderCollapseTargets, 'folderId', folderId)
      this.showAncestorFolderCollapses(folderCollapse)
    }
  }

  showAncestorFolderCollapses(currentFolderCollapse) {
    if (!currentFolderCollapse) { return }

    const parentElement = currentFolderCollapse.parentElement
    if (!parentElement) { return }

    const parentFolderCollapse = parentElement.closest(`[data-target~="${this.identifier}.folderCollapse"]`)
    if (!parentFolderCollapse || !this.element.contains(parentFolderCollapse)) { return }

    const event = new CustomEvent('group-sidebar-collapse-show', {
      bubbles: false
    })
    parentFolderCollapse.dispatchEvent(event)

    this.showAncestorFolderCollapses(parentFolderCollapse)
  }

  findElement(targets, name, value) {
    return targets.find(el => {
      const paramMap = new ParamMap(this, el)
      if (!paramMap.get(name)) { return false }

      return (value === +paramMap.get(name))
    })
  }
}