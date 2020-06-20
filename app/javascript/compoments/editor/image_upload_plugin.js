import { Plugin, PluginKey } from "prosemirror-state"
import { Decoration, DecorationSet } from "prosemirror-view"
import appNoty from '../../helpers/app_noty'

const imageUploadKey = new PluginKey("imageUpload")
const imageUploadPlugin = new Plugin({
  key: imageUploadKey,
  state: {
    init() { return DecorationSet.empty },
    apply(tr, set) {
      // Adjust decoration positions to changes made by the transaction
      set = set.map(tr.mapping, tr.doc)
      // See if the transaction adds or removes any placeholders
      let action = tr.getMeta(this)
      if (action && action.add) {
        let widget = document.createElement("placeholder")
        let deco = Decoration.widget(action.add.pos, widget, {id: action.add.id})
        set = set.add(tr.doc, [deco])
      } else if (action && action.remove) {
        set = set.remove(set.find(null, null,
                                  spec => spec.id == action.remove.id))
      }
      return set
    }
  },
  props: {
    decorations(state) { return this.getState(state) }
  }
})

export function startImageUpload(view, file, uploadUrl) {
  if (!uploadUrl) {
    appNoty('앗 뭔가 잘못되었습니다.', 'warning').show()
    return
  }
  // A fresh object to act as the ID for this upload
  let id = {}

  // Replace the selection with a placeholder
  let tr = view.state.tr
  if (!tr.selection.empty) tr.deleteSelection()
  tr.setMeta(imageUploadKey, { add: { id, pos: tr.selection.from } })
  view.dispatch(tr)

  uploadFile(file, uploadUrl).then(imageUrl => {
    if (!imageUrl) {
      appNoty('앗 뭔가 잘못되었습니다.', 'warning').show()
      return
    }

    let pos = findPlaceholder(view.state, id)
    // If the content around the placeholder has been deleted, drop
    // the image
    if (pos == null) return
    // Otherwise, insert it at the placeholder's position, and remove
    // the placeholder
    view.dispatch(view.state.tr
      .replaceWith(pos, pos, view.state.schema.nodes.image.create({ src: imageUrl }))
      .setMeta(imageUploadKey, { remove: { id } }))
  }, () => {
    // On failure, just clean up the placeholder
      view.dispatch(tr.setMeta(imageUploadKey, { remove: { id } }))
  })
}

function uploadFile(file, uploadUrl) {
  // let reader = new FileReader
  // return new Promise((accept, fail) => {
  //   reader.onload = () => accept(reader.result)
  //   reader.onerror = () => fail(reader.error)
  //   // Some extra delay to make the asynchronicity visible
  //   setTimeout(() => reader.readAsDataURL(file), 1500)
  // })

  let formData = new FormData()
  formData.append('file', file)

  let headers = new window.Headers()
  const csrfToken = document.head.querySelector("[name='csrf-token']")
  if (csrfToken) { headers.append('X-CSRF-Token', csrfToken.content) }

  return fetch(uploadUrl, {
    headers: headers,
    method: 'POST',
    credentials: 'same-origin',
    body: formData
  }).then(
    response => response.json()
  ).then(
    json => json && json.image && json.image.url
  ).catch(
    error => console.log(error)
  )
}

function findPlaceholder(state, id) {
  let decos = imageUploadKey.getState(state)
  let found = decos.find(null, null, spec => spec.id == id)
  return found.length ? found[0].from : null
}

export { imageUploadKey, imageUploadPlugin }