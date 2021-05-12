import { NodeSelection } from "prosemirror-state"
import { wrapInList, liftListItem as liftListItemInList, sinkListItem as sinkListItemInList } from "prosemirror-schema-list"
import { wrapItem, blockTypeItem, MenuItem, Dropdown, icons } from 'prosemirror-menu'
import { undo, redo } from 'prosemirror-history'
import { findParentNode } from 'prosemirror-utils'

import { toggleMark, lift, joinUp, setBlockType } from 'prosemirror-commands'

import { Prompt, TextField, ImageFileField } from './prompt'
import { destroyMark, saveMark, toggleWrap } from './commands'
import { markIsActive, getMarkAttrs, nodeCanInsert, getMarkRange, listIsActive } from './utils'
import { startImageUpload } from './image_upload_plugin'
import appNoti from '../../helpers/app_noty'
import getValidUrl from '../../helpers/valid_url'
import appNoty from '../../helpers/app_noty'

const CLASS_NAME_PREFIX = "ProseMirror-prompt"

const buildMenuItems = (schema, uploadUrl, ruleFileSize) => {
  let r = {}, type
  if (type = schema.marks.strong) {
    r.toggleStrong = markItem(type, {
      title: "굵게",
      icon: iconByClassName("fa fa-bold"),
    })
  }
  if (type = schema.marks.em) {
    r.toggleEm = markItem(type, {
      title: "기울인",
      icon: iconByClassName("fa fa-italic"),
    })
  }
  if (type = schema.marks.strike) {
    r.toggleStrike = markItem(type, {
      title: "취소선",
      icon: iconByClassName("fa fa-strikethrough"),
    })
  }
  if (type = schema.marks.underline) {
    r.toggleUnderline = markItem(type, {
      title: "밑줄",
      icon: iconByClassName("fa fa-underline"),
    })
  }
  if (type = schema.marks.link) {
    r.link = linkItem(type, {
      title: "링크",
      icon: iconByClassName("fa fa-link"),
    })
  }

  if (type = schema.nodes.image) {
    r.insertImage = insertImageItem(type, {
      title: "이미지",
      icon: iconByClassName("fa fa-image"),
    }, uploadUrl, ruleFileSize)
  }

  if (type = schema.nodes.bullet_list) {
    r.wrapBulletList = toggleListItem(type, schema, {
      title: "점 리스트",
      icon: iconByClassName("fa fa-list-ul"),
    })
  }
  if (type = schema.nodes.ordered_list) {
    r.wrapOrderedList = toggleListItem(type, schema, {
      title: "숫자 리스트",
      icon: iconByClassName("fa fa-list-ol"),
    })
  }

  if (type = schema.nodes.list_item) {
    r.liftList = liftListItem(type, {
      title: "내어쓰기",
      icon: iconByClassName("fa fa-outdent"),
    })
    r.sinkList = sinkListItem(type, {
      title: "들여쓰기",
      icon: iconByClassName("fa fa-indent"),
    })
  }

  r.joinUp = new MenuItem({
    title: "위로 합하기",
    run: joinUp,
    select: state => joinUp(state),
    icon: icons.join,
  })

  if (type = schema.nodes.blockquote) {
    r.wrapBlockQuote = toggleItem(type, {
      title: "인용",
      icon: iconByClassName("fa fa-quote-right"),
    })
  }
  if (type = schema.nodes.paragraph) {
    r.makeParagraph = toggleBlockType(type, schema.nodes.paragraph, {
      title: "일반 형식",
      icon: iconByClassName("fa fa-paragraph"),
    })
  }
  if (type = schema.nodes.heading) {
    for (let i = 1; i <= 3; i++) {
      r["makeHead" + i] = toggleBlockType(type, schema.nodes.paragraph, {
        title: '제목' + i,
        icon: iconHeadingByClassName(i),
        attrs: { level: i }
      })
    }
  }

  if (type = schema.nodes.horizontal_rule) {
    let hr = type
    r.insertHorizontalRule = new MenuItem({
      title: "가로선",
      icon: iconByClassName("fa fa-minus"),
      enable: (state) => { return nodeCanInsert(state, hr) },
      run: function run(state, dispatch) { dispatch(state.tr.replaceSelectionWith(hr.create())) }
    })
  }

  r.undo = new MenuItem({
    title: "실행 취소",
    run: undo,
    enable: state => undo(state),
    icon: iconByClassName("fa fa-undo")
  })

  r.redo = new MenuItem({
    title: "다시 실행",
    run: redo,
    enable: state => undo(state),
    icon: iconByClassName("fa fa-undo fa-rotate-180")
  })

  let cut = function (arr) {
    return arr.filter(function (x) { return x })
  }

  return [[r.makeParagraph, r.makeHead1, r.makeHead2, r.makeHead3   ], [r.toggleStrong, r.toggleEm, r.toggleStrike, r.toggleUnderline], [r.wrapBulletList, r.wrapOrderedList, r.liftList, r.sinkList, r.joinUp], [r.wrapBlockQuote, r.link, r.insertImage, r.insertHorizontalRule], [r.undo, r.redo]]
}

function cmdItem(cmd, options) {
  let mergedOptions = Object.assign({}, {
    label: options.title,
    run: cmd
  }, options)
  if ((!mergedOptions.enable || mergedOptions.enable === true) && !mergedOptions.select) {
    mergedOptions[options.enable ? "enable" : "select"] = function (state) {
      return cmd(state)
    }
  }
  if(options.debug) {
    console.log(mergedOptions)
  }
  return new MenuItem(mergedOptions)
}

function markItem(markType, options) {
  return cmdItem(
    toggleMark(markType),
    Object.assign({}, {
      active: (state) => { return markIsActive(state, markType) },
      enable: true,
    }, options)
  )
}

function chainTransactions(...commands) {
  return (state, dispatch) => {
    const dispatcher = (tr) => {
      state = state.apply(tr)
      dispatch(tr)
    };
    const last = commands.pop()
    const reduced = commands.reduce((result, command) => {
      return result || command(state, dispatcher)
    }, false)
    return reduced && last !== undefined && last(state, dispatch)
  };
}

function fromNodeInfo(selection, relativeHeight) {
  let { $from, _ } = selection

  let depth = $from.depth - relativeHeight
  if (depth < 0) {
    return null
  }

  let node = $from.node(depth)
  return {
    node,
    type: node.type,
    pos: (depth === 0 ? 0 : $from.before(depth)),
  }
}

function toggleList(listType, schema, attrs) {
  return function(state, dispatch) {
    if (!dispatch) { return true }

    const oppositeListOf = {
      bullet_list: 'ordered_list',
      ordered_list: 'bullet_list',
    }

    let { $from, _ } = state.selection
    const parentInfo = fromNodeInfo(state.selection, 1)
    const grandParentInfo = fromNodeInfo(state.selection, 2)

    let currentListInfo
    if (parentInfo && parentInfo.type.name in oppositeListOf) {
      currentListInfo = parentInfo
    } else if (grandParentInfo && grandParentInfo.type.name in oppositeListOf) {
      currentListInfo = grandParentInfo
    } else {
      currentListInfo = fromNodeInfo(state.selection, 0)
    }

    let transactions
    if (currentListInfo.type.name === listType.name) {
      return liftListItemInList(schema.nodes.list_item)(state, dispatch)
    } else if (oppositeListOf[currentListInfo.type.name] === listType.name) {
      const { tr } = state
      tr.setNodeMarkup(currentListInfo.pos, listType)
      if (dispatch) {
        dispatch(tr)
      }
      return false
    } else {
      return wrapInList(listType, attrs)(state, dispatch)
    }
  };
}

function toggleListItem(nodeType, schema, options) {
  return cmdItem(toggleList(nodeType, schema, options.attrs), options)
}

function liftListItem(nodeType, options) {
  return cmdItem(liftListItemInList(nodeType), options)
}

function sinkListItem(nodeType, options) {
  return cmdItem(sinkListItemInList(nodeType), options)
}

function linkItem(markType, options) {
  return new MenuItem(Object.assign({}, {
    active: (state) => { return markIsActive(state, markType) },
    enable: (state) => { return !state.selection.empty || markIsActive(state, markType) },
    run: (state, dispatch, view) => {
      const { tr, selection, doc } = state
      let { from, to } = selection
      const { $from, empty } = selection

      let attrs = {}
      if (empty) {
        const range = getMarkRange($from, markType)
        if (!range) { return }

        attrs = getMarkAttrs(state, markType, range)
      }

      new Prompt({
        title: "링크 걸기",
        fields: {
          href: new TextField({
            label: "주소",
            value: attrs.href,
            required: true,
          }),
          title: new TextField({
            value: attrs.title,
            label: "제목",
          })
        },
        onSave: (attrs) => {
          if (!attrs.href || attrs.href.length <= 0) {
            appNoti('주소를 입력해 주세요.', 'warning')
            return false
          }
          attrs.href = getValidUrl(attrs.href)

          saveMark(markType, attrs)(view.state, view.dispatch)
          view.focus()

          return true
        },
        onDestroy: markIsActive(state, markType) ? ((attrs) => {
          destroyMark(markType)(view.state, view.dispatch)
          view.focus()
        }) : undefined
      })
    }
  }, options))
}

function insertImageItem(nodeType, options, uploadUrl, ruleFileSize) {
  return new MenuItem(Object.assign({}, {
    enable: (state) => { return nodeCanInsert(state, nodeType) },
    run: function run(state, _, view) {
      let selection = state.selection
      let { from, to } = selection

      let attrs = {}
      if (selection instanceof NodeSelection && selection.node.type == nodeType) {
        attrs = selection.node.attrs
      }

      new Prompt({
        title: "이미지",
        fields: {
          file: new ImageFileField({ label: "선택", required: true, }),
        },
        onSave: (attrs) => {
          if (attrs.file && attrs.file[0]) {
            const currentFile = attrs.file[0]
            if (parseInt(ruleFileSize) < currentFile.size) {
              appNoty('25MB 이하의 파일만 업로드 가능합니다.', 'warning', true).show()
            } else {
              startImageUpload(view, attrs.file[0], uploadUrl)
            }
          }
          view.focus()

          return true
        }
      })
    }
  }, options))
}

function toggleItem(nodeType, options) {
  const passedOptions = Object.assign({}, {
    run: (state, dispatch) => {
      return toggleWrap(nodeType, options.attrs)(state, dispatch)
    },
    select: (state) => {
      return toggleWrap(nodeType, options.attrs)(state)
    },
    enable: () => { return true },
  }, options)
  return new MenuItem(passedOptions)
}

function toggleBlockType(nodeType, toggleType, options) {
  const passedOptions = Object.assign({}, {
    run: (state, dispatch) => {
      const isActive = nodeIsActive(state, nodeType, options.attrs)

      if (isActive) {
        return setBlockType(toggleType)(state, dispatch)
      }

      return setBlockType(nodeType, options.attrs)(state, dispatch)
    },
    active: (state) => {
      return nodeIsActive(state, nodeType, options.attrs)
    },
    enable: () => { return true },
  }, options)
  return new MenuItem(passedOptions)
}

function nodeIsActive(state, type, attrs = {}) {
  const predicate = node => node.type === type
  const parent = findParentNode(predicate)(state.selection)

  if (!Object.keys(attrs).length || !parent) {
    return !!parent
  }

  return parent.node.hasMarkup(type, attrs)
}

function iconByClassName(className) {
  let span = document.createElement("i")
  span.className = className
  return { dom: span }
}

function iconHeadingByClassName(i) {
  const icons = {
    h1: `<svg width = "1em" height = "1em" viewBox = "0 0 16 16" class="bi bi-type-h1" fill = "currentColor" xmlns = "http://www.w3.org/2000/svg" style="vertical-align: text-bottom;" >
      <path d="M8.637 13V3.669H7.379V7.62H2.758V3.67H1.5V13h1.258V8.728h4.62V13h1.259zm5.329 0V3.669h-1.244L10.5 5.316v1.265l2.16-1.565h.062V13h1.244z" />
    </svg >`,
    h2: `<svg width="1em" height="1em" viewBox="0 0 16 16" class="bi bi-type-h2" fill="currentColor" xmlns="http://www.w3.org/2000/svg" style="vertical-align: text-bottom;" >
      <path d="M7.638 13V3.669H6.38V7.62H1.759V3.67H.5V13h1.258V8.728h4.62V13h1.259zm3.022-6.733v-.048c0-.889.63-1.668 1.716-1.668.957 0 1.675.608 1.675 1.572 0 .855-.554 1.504-1.067 2.085l-3.513 3.999V13H15.5v-1.094h-4.245v-.075l2.481-2.844c.875-.998 1.586-1.784 1.586-2.953 0-1.463-1.155-2.556-2.919-2.556-1.941 0-2.966 1.326-2.966 2.74v.049h1.223z"/>
    </svg>`,
    h3: `<svg width="1em" height="1em" viewBox="0 0 16 16" class="bi bi-type-h3" fill="currentColor" xmlns="http://www.w3.org/2000/svg" style="vertical-align: text-bottom;" >
      <path d="M7.637 13V3.669H6.379V7.62H1.758V3.67H.5V13h1.258V8.728h4.62V13h1.259zm3.625-4.272h1.018c1.142 0 1.935.67 1.949 1.674.013 1.005-.78 1.737-2.01 1.73-1.08-.007-1.853-.588-1.935-1.32H9.108c.069 1.327 1.224 2.386 3.083 2.386 1.935 0 3.343-1.155 3.309-2.789-.027-1.51-1.251-2.16-2.037-2.249v-.068c.704-.123 1.764-.91 1.723-2.229-.035-1.353-1.176-2.4-2.954-2.385-1.873.006-2.857 1.162-2.898 2.358h1.196c.062-.69.711-1.299 1.696-1.299.998 0 1.695.622 1.695 1.525.007.922-.718 1.592-1.695 1.592h-.964v1.074z"/>
    </svg>`
  }

  var temp = document.createElement('div')
  temp.innerHTML = icons['h' + i]

  return { dom: temp.firstChild }
}

export { buildMenuItems }