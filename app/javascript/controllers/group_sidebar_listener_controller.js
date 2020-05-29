import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  static targets = ['channelActivation', 'channelCollapse', 'folderActivation', 'folderCollapse', 'collectionActivationController']

  consume(event) {
    const channelId = +event.detail.channelId
    const folderId = +event.detail.folderId

    const currentChannelActivation = this.findElement(this.channelActivationTargets, 'channelId', channelId)
    const currentFolderActivation = this.findElement(this.folderActivationTargets, 'folderId', folderId)
    const currentChannelCollapse = this.findElement(this.channelCollapseTargets, 'channelId', channelId)
    const currentFolderCollapse = this.findElement(this.folderCollapseTargets, 'folderId', folderId)

    if (currentChannelActivation) {
      if (!currentFolderActivation) {
        const event = new CustomEvent('group-sidebar-activation', {
          bubbles: false
        })
        currentChannelActivation.dispatchEvent(event)
      } else {
        const event = new CustomEvent('group-sidebar-activation', {
          bubbles: false
        })
        currentFolderActivation.dispatchEvent(event)
      }
    } else {
      const event = new CustomEvent('group-sidebar-deactivation-all', {
        bubbles: false
      })
      this.collectionActivationControllerTarget.dispatchEvent(event)
    }

    if (currentChannelCollapse) {
      const event = new CustomEvent('group-sidebar-collapse-show', {
        bubbles: false
      })
      currentChannelCollapse.dispatchEvent(event)
    }
    if (currentFolderCollapse) {
      this.showAncestorFolderCollapses(currentFolderCollapse)
    }

    this.channelCollapseTargets.forEach(el => {
      if (el === currentChannelCollapse) { return }
      const event = new CustomEvent('group-sidebar-collapse-hide', {
        bubbles: false
      })
      el.dispatchEvent(event)
    })

    if (!currentChannelCollapse && !currentFolderCollapse) {
      this.folderCollapseTargets.forEach(el => {
        const event = new CustomEvent('group-sidebar-collapse-hide', {
          bubbles: false
        })
        el.dispatchEvent(event)
      })
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
    if (!value) {
      return null
    }

    return targets.find(el => {
      const paramMap = new ParamMap(this, el)
      if (!paramMap.get(name)) { return false }

      return (value === +paramMap.get(name))
    })
  }
}