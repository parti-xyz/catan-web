import { getMarkRange, nodeIsActive } from './utils'
import { wrapIn, lift } from 'prosemirror-commands'

function destroyMark(type) {
  return (state, dispatch) => {
    const { tr, selection } = state
    let { from, to } = selection
    const { $from, empty } = selection

    if (empty) {
      const range = getMarkRange($from, type)

      from = range.from
      to = range.to
    }

    tr.removeMark(from, to, type)

    return dispatch(tr)
  }
}

function saveMark(type, attrs) {
  return (state, dispatch) => {
    const { tr, selection, doc } = state
    let { from, to } = selection
    const { $from, empty } = selection

    if (empty) {
      const range = getMarkRange($from, type)

      from = range.from
      to = range.to
    }

    const hasMark = doc.rangeHasMark(from, to, type)

    if (hasMark) {
      tr.removeMark(from, to, type)
    }

    tr.addMark(from, to, type.create(attrs))

    return dispatch(tr)
  }
}

function toggleWrap(type) {
  return (state, dispatch, view) => {
    const isActive = nodeIsActive(state, type)

    if (isActive) {
      return lift(state, dispatch)
    }

    return wrapIn(type)(state, dispatch, view)
  }
}

export { destroyMark, saveMark, toggleWrap }