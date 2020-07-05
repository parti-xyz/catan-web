import { Plugin } from "prosemirror-state"

export const dirtyPlugin = (element) => {
  return new Plugin({
    state: {
      init() { return false },
      apply(tr, oldDirty) {
        let newDirty = false

        if(tr.docChanged) {
          newDirty = true
        }

        if (!oldDirty && newDirty) {
          element.dispatchEvent(new CustomEvent('dirty-form:force-dirty', {
            bubbles: true,
          }))
        }

        return newDirty
      }
    }
  })
}