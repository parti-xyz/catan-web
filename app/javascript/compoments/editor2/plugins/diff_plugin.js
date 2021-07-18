import { DOMParser, DOMSerializer } from "prosemirror-model"
import { recreateTransform } from '@technik-sde/prosemirror-recreate-transform'
import { ChangeSet, simplifyChanges } from 'prosemirror-changeset'
import { Decoration, DecorationSet } from 'prosemirror-view'
import { Plugin, PluginKey } from 'prosemirror-state'
import { v4 as uuidv4 } from 'uuid'

function elementFromString(value) {
  // add a wrapper to preserve leading and trailing whitespace
  const wrappedValue = `<body>${value}</body>`

  return new window.DOMParser().parseFromString(wrappedValue, 'text/html').body
}

export const createDiffDocumentPlugin = function(schema, winnerSource, challengerSource, mode) {
  // based on https://gitlab.com/mpapp-public/prosemirror-recreate-steps/blob/master/demo/history/index.js

  // recreate transform back to base doc
  let winnerDoc = DOMParser.fromSchema(schema).parse(elementFromString(winnerSource))
  let challengerDoc = DOMParser.fromSchema(schema).parse(elementFromString(challengerSource))
  let tr = recreateTransform(challengerDoc, winnerDoc,
    {
      complexSteps: true, // Whether step types other than ReplaceStep are allowed.
      wordDiffs: true, // Whether diffs in text nodes should cover entire words.
      simplifyDiffs: true // Whether steps should be merged, where possible
    }
  )

  // create decorations corresponding to the changes
  const decorations = []
  let changeSet = ChangeSet.create(challengerDoc).addSteps(tr.doc, tr.mapping.maps)
  let changes = changeSet.changes

  // deletion
  let index = 0
  while(index < changes.length) {
    if (changes[index].inserted?.length > 0) {
      decorations.push(
        Decoration.inline(changes[index].fromB, changes[index].toB, { class: `${mode}-deletion` })
      )
    }
    index++
  }

  // insertion
  function findInsertEndIndex(startIndex) {
    for (let i=startIndex; i<changes.length; i++) {
      // if we are at the end then that's the end index
      if (i === (changes.length - 1)) return i
      // if the next change is discontinuous then this is the end index
      if ((changes[i].toA + 1) !== changes[i+1].fromA) return i
    }
  }

  index = 0
  // let trSteps = tr.steps
  while(index < changes.length) {
    let endIndex = findInsertEndIndex(index)

    let slice = challengerDoc.slice(changes[index].fromA, changes[endIndex].toA)
    let contentElement = DOMSerializer.fromSchema(schema).serializeFragment(slice.content)
    if (contentElement.children.length > 0 || (contentElement.textContent && contentElement.textContent.trim().length > 0)) {
      let controlId = uuidv4()

      let spanControl = document.createElement('span')
      spanControl.classList.add(`${mode}-insertion`)

      let spanContent = document.createElement('span')
      spanContent.classList.add('content')
      spanContent.appendChild(contentElement)
      spanControl.appendChild(spanContent)

      if (mode == 'conflict') {
        let addButton = document.createElement('div')
        addButton.classList.add('btn', 'btn-primary', 'btn-sm')
        addButton.textContent = '다시 붙여넣기'
        addButton.dataset['action'] = 'click->editor2-form#resolveConflict'
        addButton.dataset['editor2FormConflictAction'] = 'applyInsertion'
        addButton.dataset['editor2FormConflictControlId'] = controlId
        spanControl.appendChild(addButton)

        let cancelButton = document.createElement('div')
        cancelButton.classList.add('btn', 'btn-light', 'btn-sm')
        cancelButton.textContent = '취소'
        cancelButton.dataset['action'] = 'click->editor2-form#resolveConflict'
        cancelButton.dataset['editor2FormConflictAction'] = 'cancelInsertion'
        cancelButton.dataset['editor2FormConflictControlId'] = controlId
        spanControl.appendChild(cancelButton)
      }

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
  const diffPluginKey = new PluginKey('diff')
  return new Plugin({
    key: diffPluginKey,
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
        if (controlDeco && meta.action == 'applyInsertion') {
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
}
