import { Controller } from "stimulus"
import { EditorState } from "prosemirror-state"
import { EditorView } from "prosemirror-view"
import { Schema, DOMParser, DOMSerializer } from "prosemirror-model"
import { schema as basicSchema } from "prosemirror-schema-basic"
import { exampleSetup } from "prosemirror-example-setup"
import { addListNodes } from "prosemirror-schema-list"

import { linkTooltipPlugin } from '../compoments/editor/link_tooltip_plugin'
import { buildMenuItems } from '../compoments/editor/menus'

export default class extends Controller {
  static targets = ['editorSource']

  connect() {
    if (!this.editorSourceTarget) { return }

    this.editorElement = document.createElement('div')
    this.editorSourceTarget.insertAdjacentElement("afterend", this.editorElement)
    this.editorSourceTarget.style.display = 'none'

    // Mix the nodes from prosemirror-schema-list into the basic schema to
    // create a schema with list support.
    const currentSchema = new Schema({
      nodes: addListNodes(basicSchema.spec.nodes, "paragraph block*", "block"),
      marks: basicSchema.spec.marks.append(this.customMarks())
    })

    this.editorView = new EditorView(this.editorElement, {
      state: EditorState.create({
        doc: DOMParser.fromSchema(currentSchema).parse(this.editorSourceTarget),
        plugins: exampleSetup({
          schema: currentSchema,
          menuContent: buildMenuItems(currentSchema),
        }).concat(linkTooltipPlugin)
      }),
    })
  }

  disconnect() {
    if (this.editorElement) {
      this.editorElement.parentNode.removeChild(this.editorElement)
    }
  }

  getHTML() {
    if (!this.editorView) { return null }

    const div = document.createElement('div')
    const fragment = DOMSerializer
      .fromSchema(this.editorSchema)
      .serializeFragment(this.editorState.doc.content)

    div.appendChild(fragment)

    return div.innerHTML
  }

  onSubmit(event) {
    const newSourceTargetValue = this.getHTML()
    if (!newSourceTargetValue) {
      event.preventDefault()
      return
    }

    this.editorSourceTarget.value = newSourceTargetValue
  }

  customMarks() {
    return {
      strike: {
        parseDOM: [
          {
            tag: 's',
          },
          {
            tag: 'del',
          },
          {
            tag: 'strike',
          },
          {
            style: 'text-decoration',
            getAttrs: value => value === 'line-through',
          },
        ],
        toDOM: () => ['s', 0],
      },
      underline: {
        parseDOM: [
          {
            tag: 'u',
          },
          {
            style: 'text-decoration',
            getAttrs: value => value === 'underline',
          },
        ],
        toDOM: () => ['u', 0],
      }
    }
  }

  get editorState() {
    return this.editorView ? this.editorView.state : null
  }

  get editorSchema() {
    return this.editorState ? this.editorState.schema : null
  }
}