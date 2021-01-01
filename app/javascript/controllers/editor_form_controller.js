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
import scrollIntoView from 'scroll-into-view'

import { linkTooltipPlugin } from '../compoments/editor/link_tooltip_plugin'
import { imageUploadPlugin } from '../compoments/editor/image_upload_plugin'
import { dirtyPlugin } from '../compoments/editor/dirty_plugin'
import { buildMenuItems } from '../compoments/editor/menus'
import { recreateTransform } from '@technik-sde/prosemirror-recreate-transform'
import ParamMap from '../helpers/param_map'
import { resizableImage } from '../compoments/editor/schema'
import { ImageView } from '../compoments/editor/image_view'

export default class extends Controller {
  static targets = ['source', 'conflictSource', 'versionSource']

  connect() {
    if (!this.sourceTarget) { return }

    this.editorElement = document.createElement('div')
    this.editorElement.classList.add('editor-view')
    this.sourceTarget.insertAdjacentElement("afterend", this.editorElement)
    this.sourceTarget.style.display = 'none'

    // Mix the nodes from prosemirror-schema-list into the basic schema to
    // create a schema with list support.
    let nodes = basicSchema.spec.nodes.update('image', resizableImage)

    const currentSchema = new Schema({
      nodes: addListNodes(nodes, "paragraph block*", "block"),
      marks: basicSchema.spec.marks.append(this.customMarks())
    })

    let mapKeys = {
      "Shift-Tab": liftListItem(currentSchema.nodes.list_item),
      Tab: this.sinkListItemOrWrapInList(currentSchema)
    }

    const uploadUrl = this.data.get('uploadUrl')
    const ruleFileSize = this.element.dataset.ruleFilesize

    let doc
    let plugins = exampleSetup({
      schema: currentSchema,
      menuBar: (this.data.get('readOnly') == 'true' ? false : true),
      menuContent: (this.data.get('readOnly') != 'true' ? buildMenuItems(currentSchema, uploadUrl, ruleFileSize) : []),
      mapKeys,
    }).concat(
      linkTooltipPlugin,
      imageUploadPlugin,
      dirtyPlugin(this.element),
      keymap(mapKeys)
    )

    let editorFormClasses = this.sourceTarget.dataset.editorFormClasses
    if (editorFormClasses) {
      plugins.push(
        new Plugin({
          props: {
            attributes: {
              "class": editorFormClasses,
            }
          }
        })
      )
    }

    if (this.hasConflictSourceTarget) {
      let diff = this.computeConflictDocument(currentSchema, this.sourceTarget, this.conflictSourceTarget)
      doc = diff.doc
      plugins = plugins.concat(diff.plugins)
    } else if (this.hasVersionSourceTarget) {
      let diff = this.computeVersionDocument(currentSchema, this.sourceTarget, this.versionSourceTarget)
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
      },
      nodeViews: {
        image(node, view, getPos) { return new ImageView(node, view, getPos) }
      },
      editable: (state) => (this.data.get('readOnly') != 'true')
    })

    this.editorView.dom.addEventListener('focus', () => {
      const foucsEvent = new CustomEvent('editor-form:focus', {
        bubbles: true
      })
      this.editorView.dom.dispatchEvent(foucsEvent)
    })
  }

  disconnect() {
    if (this.editorElement) {
      this.editorElement.remove()
    }
  }

  serialize() {
    if (!this.editorView) { return null }

    const div = document.createElement('div')
    const fragment = DOMSerializer
      .fromSchema(this.editorSchema)
      .serializeFragment(this.editorState.doc.content, { preserveWhiteSpace: true })

    div.appendChild(fragment)

    var result = []
    var node = div.childNodes[0]
    while (node != null) {
      if (node.nodeType == 3) { /* Fixed a bug here. Thanks @theazureshadow */
        node.nodeValue = node.nodeValue.replace(/(\r)?\n/g, ' ').replace(/\s+/g, ' ')
      }

      if (node.hasChildNodes()) {
        node = node.firstChild;
      }
      else {
        while (node.nextSibling == null && node != div) {
          node = node.parentNode;
        }
        node = node.nextSibling;
      }
    }

    return div.innerHTML
  }

  insertText(text) {
    if (!this.editorView || !this.editorState) { return }

    const { tr } = this.editorState
    tr.insertText(text, 1)
    this.editorView.dispatch(tr)
  }

  focus() {
    if (!this.editorView) { return }

    this.editorView.focus()

    scrollIntoView(this.editorView.dom, {
      cancellable: true,
      align: {
        topOffset: 100,
      }
    })
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
    let tr = recreateTransform(conflictDoc, baseDoc,
      {
        complexSteps: true, // Whether step types other than ReplaceStep are allowed.
        wordDiffs: false, // Whether diffs in text nodes should cover entire words.
        simplifyDiffs: true // Whether steps should be merged, where possible
      }
    )

    // create decorations corresponding to the changes
    const decorations = []
    let changeSet = ChangeSet.create(conflictDoc).addSteps(tr.doc, tr.mapping.maps);
    let changes = changeSet.changes;

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
      if (changes[endIndex].inserted?.length > 0) {
        decorations.push(
          Decoration.inline(changes[index].fromB, changes[endIndex].toB, { class: 'conflict-deletion' })
        )
      }
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

    let marks = tr.steps
    while(index < changes.length) {
      let endIndex = findInsertEndIndex(index)

      if (marks[endIndex].slice?.content?.content?.length > 0) {

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
              [Decoration.inline(from, to)]
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

  computeVersionDocument(schema, baseSource, versionSource) {
    // based on https://gitlab.com/mpapp-public/prosemirror-recreate-steps/blob/master/demo/history/index.js

    // recreate transform back to base doc
    let baseDoc = DOMParser.fromSchema(schema).parse(baseSource)
    let versionDoc = DOMParser.fromSchema(schema).parse(versionSource)
    let tr = recreateTransform(versionDoc, baseDoc,
      {
        complexSteps: true, // Whether step types other than ReplaceStep are allowed.
        wordDiffs: false, // Whether diffs in text nodes should cover entire words.
        simplifyDiffs: true // Whether steps should be merged, where possible
      }
    )

    // create decorations corresponding to the changes
    let changeSet = ChangeSet.create(versionDoc).addSteps(tr.doc, tr.mapping.maps)
    let changes = changeSet.changes
    let marks = tr.steps

    // mark
    function findMarkEndIndex(startIndex) {
      for (let i = startIndex; i < marks.length; i++) {
        // if we are at the end then that's the end index
        if (i === (marks.length - 1))
          return i;
        // if the next change is discontinuous then this is the end index
        if ((marks[i].to + 1) !== marks[i + 1].from)
          return i;
      }
    }

    let index = 0;
    const decorations = []
    while (index < marks.length) {
      let endIndex = findMarkEndIndex(index)
      if (marks[endIndex].slice?.content?.content?.length > 0) {
        decorations.push(
          Decoration.inline(marks[index].from, marks[endIndex].to, { class: 'version-deletion' })
        )
      }
      index = endIndex + 1
    }

    // deletion
    function findDeleteEndIndex(startIndex) {
      for (let i = startIndex; i < changes.length; i++) {
        // if we are at the end then that's the end index
        if (i === (changes.length - 1))
          return i;
        // if the next change is discontinuous then this is the end index
        if ((changes[i].toB + 1) !== changes[i + 1].fromB)
          return i;
      }
    }

    index = 0;
    while (index < changes.length) {
      let endIndex = findDeleteEndIndex(index)
      if (changes[endIndex].inserted?.length > 0) {
        decorations.push(
          Decoration.inline(changes[index].fromB, changes[endIndex].toB, { class: 'version-deletion' })
        )
      }
      index = endIndex + 1
    }

    // insertion
    function findInsertEndIndex(startIndex) {
      for (let i = startIndex; i < changes.length; i++) {
        // if we are at the end then that's the end index
        if (i === (changes.length - 1))
          return i
        // if the next change is discontinuous then this is the end index
        if ((changes[i].toA + 1) !== changes[i + 1].fromA)
          return i
      }
    }

    index = 0
    while (index < changes.length) {
      let endIndex = findInsertEndIndex(index)

      // apply the insertion
      let slice = versionDoc.slice(changes[index].fromA, changes[endIndex].toA)
      let contentElement = DOMSerializer.fromSchema(schema).serializeFragment(slice.content)
      if (contentElement.children.length > 0 || contentElement.textContent) {
        let controlId = uuidv4()

        let spanControl = document.createElement('span')
        spanControl.classList.add('version-insertion')

        let spanContent = document.createElement('span')
        spanContent.classList.add('content')
        spanContent.appendChild(contentElement)
        spanControl.appendChild(spanContent)

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
    let versionPlugin = new Plugin({
      key: new PluginKey('version'),
      state: {
        init() { return initDecorationSet },
        apply(tr, decorationSet) {
          return decorationSet
        }
      },
      props: {
        decorations(state) { return this.getState(state) }
      }
    })
    this.versionPlugin = versionPlugin

    // return
    return {
      doc: tr.doc,
      plugins: [versionPlugin]
    }
  }
}