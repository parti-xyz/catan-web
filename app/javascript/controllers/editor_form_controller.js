import { Controller } from "stimulus"
import { EditorState, Plugin, PluginKey, NodeSelection } from "prosemirror-state"
import { Decoration, DecorationSet, EditorView } from "prosemirror-view"
import { Schema, DOMParser, DOMSerializer } from "prosemirror-model"
import { schema as basicSchema } from "prosemirror-schema-basic"
import { exampleSetup } from "prosemirror-example-setup"
import { addListNodes, liftListItem, sinkListItem, wrapInList } from "prosemirror-schema-list"
import { keymap } from "prosemirror-keymap"
import { ChangeSet, simplifyChanges } from 'prosemirror-changeset'
import { v4 as uuidv4 } from 'uuid'

import { linkTooltipPlugin } from '../compoments/editor/link_tooltip_plugin'
import { buildMenuItems } from '../compoments/editor/menus'
import { recreateTransform } from '../compoments/editor/recreate'
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  static targets = ['source', 'conflictSource']

  connect() {
    if (!this.sourceTarget) { return }

    this.editorElement = document.createElement('div')
    this.sourceTarget.insertAdjacentElement("afterend", this.editorElement)
    this.sourceTarget.style.display = 'none'

    // Mix the nodes from prosemirror-schema-list into the basic schema to
    // create a schema with list support.
    const currentSchema = new Schema({
      nodes: addListNodes(basicSchema.spec.nodes, "paragraph block*", "block"),
      marks: basicSchema.spec.marks.append(this.customMarks())
    })

    let mapKeys = {
      "Shift-Tab": liftListItem(currentSchema.nodes.list_item),
      Tab: this.sinkListItemOrWrapInList(currentSchema)
    }

    let doc
    let plugins = exampleSetup({
      schema: currentSchema,
      menuContent: buildMenuItems(currentSchema),
      mapKeys,
    }).concat(linkTooltipPlugin, keymap(mapKeys))

    if (this.hasConflictSourceTarget) {
      let diff = this.computeConflictDocument(currentSchema, this.sourceTarget, this.conflictSourceTarget)
      doc = diff.doc
      plugins = plugins.concat(diff.plugins)
    } else {
      doc = DOMParser.fromSchema(currentSchema).parse(this.sourceTarget)
    }

    this.editorView = new EditorView(this.editorElement, {
      state: EditorState.create({
        doc,
        plugins,
      }),
      attributes: {
        spellCheck: false,
      }
    })
  }

  disconnect() {
    if (this.editorElement) {
      this.editorElement.parentNode.removeChild(this.editorElement)
    }
  }

  serialize() {
    if (!this.editorView) { return null }

    const div = document.createElement('div')
    const fragment = DOMSerializer
      .fromSchema(this.editorSchema)
      .serializeFragment(this.editorState.doc.content)

    div.appendChild(fragment)

    return div.innerHTML
  }

  hasDangerConflict() {
    if (!this.editorState || !this.conflictPlugin) { return false }

    let decos = this.conflictPlugin.getState(this.editorState)
    let found = decos.find(null, null, spec => spec.danger)
    return found.length > 0
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

  computeConflictDocument(schema, baseSource, conflictSource) {
    // based on https://gitlab.com/mpapp-public/prosemirror-recreate-steps/blob/master/demo/history/index.js

    // recreate transform back to base doc
    let baseDoc = DOMParser.fromSchema(schema).parse(baseSource)
    let conflictDoc = DOMParser.fromSchema(schema).parse(conflictSource)
    let tr = recreateTransform(conflictDoc, baseDoc, true, true)

    // create decorations corresponding to the changes
    const decorations = []
    let changeSet = ChangeSet.create(conflictDoc).addSteps(tr.doc, tr.mapping.maps);
    let changes = simplifyChanges(changeSet.changes, tr.doc);

    // deletion
    function findDeleteEndIndex(startIndex) {
      for (let i=startIndex; i<changes.length; i++) {
        // if we are at the end then that's the end index
        if (i === (changes.length - 1))
          return i;
        // if the next change is discontinuous then this is the end index
        if ((changes[i].toB + 1) !== changes[i+1].fromB)
          return i;
      }
    }

    let index = 0;
    while(index < changes.length) {
      let endIndex = findDeleteEndIndex(index)
      decorations.push(
        Decoration.inline(changes[index].fromB, changes[endIndex].toB, { class: 'conflict-deletion' })
      )
      index = endIndex + 1
    }

    // insertion
    function findInsertEndIndex(startIndex) {
      for (let i=startIndex; i<changes.length; i++) {
        // if we are at the end then that's the end index
        if (i === (changes.length - 1))
          return i
        // if the next change is discontinuous then this is the end index
        if ((changes[i].toA + 1) !== changes[i+1].fromA)
          return i
      }
    }
    index = 0
    while(index < changes.length) {
      let endIndex = findInsertEndIndex(index)

      // apply the insertion
      let slice = conflictDoc.slice(changes[index].fromA, changes[endIndex].toA)
      let contentElement = DOMSerializer.fromSchema(schema).serializeFragment(slice.content)
      if (contentElement.children.length > 0 || contentElement.textContent) {
        let controlId = uuidv4()

        let spanControl = document.createElement('span')
        spanControl.classList.add('conflict-insertion')

        let spanContent = document.createElement('span')
        spanContent.classList.add('content')
        spanContent.appendChild(contentElement)
        spanControl.appendChild(spanContent)

        let addButton = document.createElement('div')
        addButton.classList.add('btn', 'btn-primary', 'btn-sm')
        addButton.textContent = '다시 붙여넣기'
        addButton.dataset['action'] = 'click->editor-form#applyConflictPlugin'
        addButton.dataset['editorFormConflictAction'] = 'applyInsertion'
        addButton.dataset['editorFormConflictControlId'] = controlId
        spanControl.appendChild(addButton)

        let cancelButton = document.createElement('div')
        cancelButton.classList.add('btn', 'btn-light', 'btn-sm')
        cancelButton.textContent = '취소'
        cancelButton.dataset['action'] = 'click->editor-form#applyConflictPlugin'
        cancelButton.dataset['editorFormConflictAction'] = 'cancelInsertion'
        cancelButton.dataset['editorFormConflictControlId'] = controlId
        spanControl.appendChild(cancelButton)

        decorations.push(
          Decoration.widget(changes[index].toB, spanControl, {
            id: controlId,
            content: slice.content,
            danger: true,
          })
        )
      }

      index = endIndex + 1
    }

    // plugin to apply diff decorations
    const initDecorationSet = DecorationSet.create(tr.doc, decorations)
    let conflictPlugin = new Plugin({
      key: new PluginKey('conflict'),
      state: {
        init() { return initDecorationSet },
        apply(tr, decorationSet) {
          // Adjust decoration positions to changes made by the transaction
          decorationSet = decorationSet.map(tr.mapping, tr.doc)

          let meta = tr.getMeta(this)
          if (!meta || !meta.action || !meta.controlId) { return decorationSet }

          const controlDeco = decorationSet.find(null, null, spec =>
            spec.id == meta.controlId)[0]

          decorationSet = decorationSet.remove([controlDeco])
          if (meta.action == 'applyInsertion') {
            const from = controlDeco.from - controlDeco.spec.content.size
            const to = controlDeco.from
            decorationSet = decorationSet.add(tr.doc,
              [Decoration.inline(from, to, { class: 'conflict-insertion' })]
            )
          }

          return decorationSet
        }
      },
      props: {
        decorations(state) { return this.getState(state) }
      }
    })
    this.conflictPlugin = conflictPlugin

    // return
    return {
      doc: tr.doc,
      plugins: [conflictPlugin]
    }
  }

  applyConflictPlugin(event) {
    event.preventDefault()

    if (!this.editorState && !this.conflictPlugin) { return }

    const paramMap = new ParamMap(this, event.currentTarget)
    const action = paramMap.get('conflictAction')
    const controlId = paramMap.get('conflictControlId')

    let tr = this.editorState.tr

    const controlDeco = this.findConflictContentDeco(controlId)
    if (controlDeco) {
      if (action == 'applyInsertion') {
        tr.insert(controlDeco.to, controlDeco.spec.content)
      }
    }

    tr.setMeta(this.conflictPlugin, { action, controlId })
    this.editorView.dispatch(tr)
  }

  findConflictContentDeco(controlId) {
    let decos = this.conflictPlugin.getState(this.editorState, )
    let found = decos.find(null, null, spec => spec.id == controlId)
    return found.length ? found[0] : null
  }

  sinkListItemOrWrapInList(schema) {
    let sinkListItemType = schema.nodes.list_item
    let wrapInListItemType = schema.nodes.bullet_list
    return function (state, dispatch) {
      let result = (sinkListItem(sinkListItemType))(state, dispatch)
      if (result) { return true }

      (wrapInList(wrapInListItemType))(state, dispatch)

      return true
    }
  }
}