import { Controller } from "stimulus"

import { v4 as uuidv4 } from 'uuid'
import scrollIntoView from 'scroll-into-view'

// import { linkTooltipPlugin } from '../compoments/editor/link_tooltip_plugin'
// import { imageUploadPlugin } from '../compoments/editor/image_upload_plugin'
// import { dirtyPlugin } from '../compoments/editor/dirty_plugin'
// import { buildMenuItems } from '../compoments/editor/menus'
// import { recreateTransform } from '@technik-sde/prosemirror-recreate-transform'
// import ParamMap from '../helpers/param_map'
// import { resizableImage } from '../compoments/editor/schema'
// import { ImageView } from '../compoments/editor/image_view'

import { Schema, DOMParser, DOMSerializer } from "prosemirror-model"

import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import Link from '@tiptap/extension-link'
import Table from '@tiptap/extension-table'
import TableRow from '@tiptap/extension-table-row'
import TableCell from '@tiptap/extension-table-cell'
import TableHeader from '@tiptap/extension-table-header'
import Gapcursor from '@tiptap/extension-gapcursor'

import ParamMap from '../helpers/param_map'
import { ResizableImage } from '../compoments/editor2/nodes/resizable_image'
import { createLinkTooltipPlugin } from '../compoments/editor2/plugins/link_tooltip_plugin'
import { createImageUploadPlugin } from '../compoments/editor2/plugins/image_upload_plugin'
import { computeConflictDocument } from '../compoments/editor2/plugins/conflict_plugin'


import { camelize } from '../helpers/string'
import MenuBar from '../compoments/editor2/menu_bar'

export default class extends Controller {
  static targets = ['target', 'source', 'conflictSource',
                    'versionSource', 'menuBarWrapper',
                    'menuBar', 'menuBarSpacer', 'menu']

  connect() {
    if (!this.sourceTarget || !this.targetTarget) { return }

    this.targetTarget.classList.add('editor-view')
    this.sourceTarget.style.display = 'none'

    if (this.editor && !this.editor.isDestroyed) {
      this.editor.destroy()
    }

    this.editor = new Editor({
      element: this.targetTarget,
      extensions: [
        StarterKit,
        Underline,
        Link.configure({
          openOnClick: false,
        }),
        ResizableImage,
        Gapcursor,
        Table.configure({
          resizable: true,
        }),
        TableRow,
        TableHeader,
        TableCell,
      ],
      content: this.sourceTarget.textContent,TableRow,
        TableHeader,
        TableCell,
      editorProps: {
        attributes: {
          spellcheck: 'false',
        },
      },
      editable: this.data.get('readOnly') != 'true',
    })

    if (this.hasConflictSourceTarget) {
      const { conflictDoc, conflictDocumentPlugin } = computeConflictDocument(
        this.editor.schema,
        this.sourceTarget,
        this.conflictSourceTarget
      )
      this.reconfigureDoc(conflictDoc)
      this.conflictDocumentPlugin = conflictDocumentPlugin
      this.editor.registerPlugin(this.conflictDocumentPlugin)
    // } else if (this.hasVersionSourceTarget) {
    //   let diff = this.computeVersionDocument(currentSchema, this.sourceTarget, this.versionSourceTarget)
    //   doc = diff.doc
    //   plugins = plugins.concat(diff.plugins)
    } else {
      // this.reconfigureDoc(DOMParser.fromSchema(this.editor.schema).parse(this.sourceTarget))
    }

    this.linkTooltipPlugin = createLinkTooltipPlugin()
    this.editor.registerPlugin(this.linkTooltipPlugin)

    this.imageUploadPlugin = createImageUploadPlugin()
    this.editor.registerPlugin(this.imageUploadPlugin)

    let editorFormClasses = this.sourceTarget.dataset.editorFormClasses
    if (editorFormClasses) {
      this.editor.registerPlugin(new Plugin({
          props: {
            attributes: {
              "class": editorFormClasses,
            }
          }
        })
      )
    }

    /*
    let fix = fixTables(state)
    if (fix) {
      state = state.apply(fix.setMeta("addToHistory", false))
    }
    document.execCommand("enableObjectResizing", false, false)
    document.execCommand("enableInlineTableEditing", false, false)
    */

    this.editor.view.dom.addEventListener('focus', () => {
      this.editor.view.dom.dispatchEvent(new CustomEvent('editor-form:focus', { bubbles: true }))
    })

    this.menuBar = new MenuBar(
      this.editor, this.menuBarWrapperTarget,
      this.menuBarTarget, this.menuBarSpacerTarget,
      this.menuTargets)
  }

  disconnect() {
    if (this.editor) {
      if (this.linkTooltipPlugin) this.editor.unregisterPlugin(this.linkTooltipPlugin.key)
      if (this.imageUploadPlugin) this.editor.unregisterPlugin(this.imageUploadPlugin.key)
      if (this.conflictDocumentPlugin) this.editor.unregisterPlugin(this.conflictDocumentPlugin.key)

      this.editor.destroy()
      this.editor = null
    }
  }

  handleMenu(event) {
    this.menuBar.handleClick(event)
  }

  serialize() {
    if (!this.editor) { return null }

    const fragment = DOMSerializer
    .fromSchema(this.editor.schema)
    .serializeFragment(this.editor.state.doc.content, { preserveWhiteSpace: true })

    const temporaryDocument = document.implementation.createHTMLDocument()
    const div = temporaryDocument.createElement('div')
    div.appendChild(fragment)

    var result = []
    var node = div.childNodes[0]
    while (node != null) {
      if (node.nodeType === Node.TEXT_NODE) { /* Fixed a bug here. Thanks @theazureshadow */
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

    div.getElementsByTagName("table").forEach(tableElement => {
      tableElement.querySelectorAll("td, th").forEach(cellElement => {
        let widthAttribute = cellElement.getAttribute("data-colwidth")
        let widthValues = widthAttribute && /^\d+(,\d+)*$/.test(widthAttribute) ? widthAttribute.split(",").map(s => Number(s)) : null
        let colspanValue = Number(cellElement.getAttribute("colspan") || 1)
        if (widthValues && widthValues.length == colspanValue) {
          cellElement.style.width = `${widthValues.reduce((sum, widthValue) => sum + widthValue)}px`
        }
      })

      tableElement.outerHTML = `<div class="tableWrapper">${tableElement.outerHTML}</div>`
    })

    return div.innerHTML
  }

  reconfigureDoc(newDoc) {
    const newState = this.editor.state.reconfigure({ doc })
    this.editor.view.updateState(newState)

    this.editor
      .chain()
      .command(({ tr }) => {
        const { doc } = tr
        const selection = TextSelection.create(doc, 0, doc.content.size)
        tr.setSelection(selection)
          .replaceSelectionWith(newDoc, false)
          .setMeta('preventUpdate', true)
        return true
      })
      .run()
  }

  insertText(text) {
    if (!this.editor) return

    this.editor
      .chain()
      .focus()
      .command(({ tr }) => {
        tr.insertText(text, 1)
        return true
      })
      .run()
  }

  hasDangerConflict() {
    if (!this.editorState || !this.conflictDocumentPlugin) { return false }

    let decos = this.conflictPlugin.getState(this.editorState)
    let found = decos.find(null, null, spec => spec.danger)
    return found.length > 0
  }

  resolveConflict(event) {
    event.preventDefault()

    if (!this.editor || !this.conflictPlugin) { return }

    const paramMap = new ParamMap(this, event.currentTarget)
    const action = paramMap.get('conflictAction')
    const controlId = paramMap.get('conflictControlId')

    let tr = this.editor.state.tr

    this.editor
      .chain()
      .focus()
      .command(({ tr }) => {
        const controlDeco = this.findConflictContentDeco(controlId)
        if (controlDeco) {
          if (action == 'applyInsertion') {
            tr.insert(controlDeco.to, controlDeco.spec.content)
          }
        }

        tr.setMeta(this.conflictPlugin, { action, controlId })
        return true
      })
      .run()
  }

  findConflictContentDeco(controlId) {
    let decos = this.conflictPlugin.getState(this.editorState, )
    let found = decos.find(null, null, spec => spec.id == controlId)
    return found.length ? found[0] : null
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