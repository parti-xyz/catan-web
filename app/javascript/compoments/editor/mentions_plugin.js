import { suggestionsPlugin, triggerCharacter } from '@quartzy/prosemirror-suggestions'
import { v4 as uuidv4 } from 'uuid'

const mentionNodeSpec = {
  attrs: {
    type: {},
    id: {},
    label: {},
  },

  group: 'inline',
  inline: true,
  selectable: false,
  atom: true,

  toDOM: node => [
    'span',
    {
      class: 'mention',
      'data-mention-type': node.attrs.type,
      'data-mention-id': node.attrs.id,
      'data-mention-label': node.attrs.label,
    },
    node.attrs.label,
  ],

  parseDOM: [
    {
      tag: 'span[data-mention-type][data-mention-id][data-mention-label]',

      /**
       * @param {Element} dom
       * @returns {{type: string, id: string, label: string}}
       */
      getAttrs: dom => {
        const type = dom.getAttribute('data-mention-type')
        const id = dom.getAttribute('data-mention-id')
        const label = dom.getAttribute('data-mention-label')
        return { type, id, label }
      },
    },
  ],
}

export function addMentionNodes(nodes) {
  return nodes.append({
    mention: mentionNodeSpec,
  })
}

class MentionsPluginBuilder {
  constructor() {
    this.uuid = uuidv4()
  }

  build() {
    // let onEnter = ().bind(this)
    return suggestionsPlugin({
      debug: true,
      matcher: triggerCharacter("@", { allowSpaces: true }),
      onEnter: args => {
        let { view } = args

        view.dom.parentNode.insertAdjacentHTML('beforeend', this.dropdownTemplate())
        this.suggestionsDropdown = document.getElementById(this.uuid)

        return false
      },
      onChange: args => {
        if (!this.suggestionsDropdown) { return }

        const dropdownController = this.suggestionsDropdown['remote-dropdown-controller']
        if (!dropdownController) { return }
        dropdownController.changeUrl(`/front/autocomplete?${ new URLSearchParams({
          q: text,
        }).toString() }`)

        let { view, text, range } = args
        if (!text || text.length < 3) {
          return
        }
        let { from, to } = range

        // These are in screen coordinates
        let start = view.coordsAtPos(from), end = view.coordsAtPos(to)
        // The box in which the tooltip is positioned, to use as base
        let box = this.suggestionsDropdown.offsetParent.getBoundingClientRect()
        // Find a center-ish x position from the selection endpoints (when
        // crossing lines, end may be more to the left)
        let left = Math.max((start.left + end.left) / 2, start.left + 3)
        this.suggestionsDropdown.style.left = (left - box.left) + "px"
        this.suggestionsDropdown.style.bottom = (box.bottom - start.top) + "px"

        jQuery(this.suggestionsDropdown).dropdown('show')
        dropdownController.handleShow()
        return false
      },
      onExit(args) {
        console.log("stop", args)

        if (this.suggestionsDropdown) {
          this.suggestionsDropdown.remove()
        }

        return false
      },
      onKeyDown({ view, event }) {
        console.log(event.key)
        return false
      },
    })
  }

  dropdownTemplate() {
    return `
      <div
        id=${this.uuid}
        class="dropdown"
        data-controller="phone-dropdown remote-dropdown"
      >
        <div
          class="dropdown-menu dropdown-menu-right"
          data-target="remote-dropdown.menu"
        >
          <div
            class="dropdown-item"
          >
            <i class="fa fa-spinner fa-pulse"></i>
            <span>로딩 중...</span>
          </div>
        </div>
      </div>
    `
  }
}

const mentionsPlugin = new MentionsPluginBuilder().build()
export { mentionsPlugin }
