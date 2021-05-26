import { Plugin, PluginKey } from 'prosemirror-state'
import { markIsActive, getMarkRange, getMarkAttrs } from './utils'

const linkTooltipPluginKey = new PluginKey('linkTooltip')
class LinkTooltipView {
  constructor(view) {
    this.tooltip = document.createElement('div')
    document.body.appendChild(this.tooltip)

    this.update(view, null)
  }

  render(view) {
    const { state } = view
    const { from, to, empty } = state.selection

    if (!empty) { return '' }

    const href = this.getHref(state)
    if (!href) { return '' }

    const start = view.coordsAtPos(from)
    const end = view.coordsAtPos(to)
    const box = this.tooltip.offsetParent.getBoundingClientRect()
    const left = Math.max((start.left + end.left) / 2, start.left + 3)

    const leftSpacing = `${left - box.left}px`

    let topSpacing, bottomSpacing

    const buffer = 10
    const contentTop = view.docView.contentDOM.getBoundingClientRect().top
    const isBottomPosition = this.tooltip.firstElementChild && (end.bottom - contentTop) > (this.tooltip.firstElementChild.offsetHeight + buffer)
    if (isBottomPosition) {
      topSpacing = 'auto'
      bottomSpacing = `${box.bottom - start.top}px`
    } else {
      topSpacing = `${end.bottom - box.top}px`
      bottomSpacing = 'auto'
    }

    return `
      <div
        class="ProseMirror-link-tooltip-plugin ${isBottomPosition ? '-bottom' : '-top'}"
        style="
          left: ${leftSpacing};
          top: ${topSpacing};
          bottom: ${bottomSpacing};
        "
      >
        <a href="${href}" target="_blank"><i class="fa fa-external-link"></i> 링크 열기</a>
      </div>
    `
  }

  update(view, lastState) {
    const { state } = view

    // Don't do anything if the document/selection didn't change
    if (lastState && lastState.doc.eq(state.doc) &&
        lastState.selection.eq(state.selection)) { return }

    const linkType = state.schema.marks.link
    if (!markIsActive(state, linkType)) {
      this.tooltip.innerHTML = ''
      return
    }

    this.tooltip.innerHTML = this.render(view)
  }

  destroy() {
    this.tooltip.remove()
  }

  getHref(state) {
    const linkMarkType = state.schema.marks.link
    if (!linkMarkType) { return }

    const { $from } = state.selection
    const range = getMarkRange($from, linkMarkType)
    if (!range) { return }

    const attrs = getMarkAttrs(state, linkMarkType, range)
    if (!attrs.href) { return }

    return attrs.href
  }
}

export const createLinkTooltipPlugin = () => {
  return new Plugin({
    key: linkTooltipPluginKey,
    view: view => new LinkTooltipView(view),
  })
}