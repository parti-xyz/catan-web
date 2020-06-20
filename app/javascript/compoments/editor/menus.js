import { NodeSelection } from "prosemirror-state"
import { wrapInList, liftListItem as liftListItemInList, sinkListItem as sinkListItemInList } from "prosemirror-schema-list"
import { wrapItem, blockTypeItem, MenuItem, Dropdown, icons } from 'prosemirror-menu'
import { undo, redo } from 'prosemirror-history'

import { toggleMark, lift, joinUp } from 'prosemirror-commands'

import { Prompt, TextField, ImageFileField } from './prompt'
import { destroyMark, saveMark, toggleWrap } from './commands'
import { markIsActive, getMarkAttrs, nodeCanInsert, getMarkRange } from './utils'
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
    r.wrapBulletList = wrapListItem(type, {
      title: "점 리스트",
      icon: iconByClassName("fa fa-list-ul"),
    })
  }
  if (type = schema.nodes.ordered_list) {
    r.wrapOrderedList = wrapListItem(type, {
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
    r.makeParagraph = blockTypeItem(type, {
      title: "일반 형식",
      label: "일반 형식"
    })
  }
  if (type = schema.nodes.heading) {
    for (let i = 1; i <= 5; i++) {
      r["makeHead" + i] = blockTypeItem(type, {
        title: '제목' + i,
        label: '제목' + i,
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

  r.typeMenu = new Dropdown(cut([r.makeParagraph, r.makeHead1, r.makeHead2, r.makeHead3, r.makeHead4, r.makeHead5, r.makeHead6
  ]), {
    label: "스타일",
  })

  return [[r.typeMenu, r.toggleStrong, r.toggleEm, r.toggleStrike, r.toggleUnderline], [r.wrapBulletList, r.wrapOrderedList, r.liftList, r.sinkList, r.joinUp], [r.wrapBlockQuote, r.link, r.insertImage, r.insertHorizontalRule], [r.undo, r.redo]]
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

function wrapListItem(nodeType, options) {
  return cmdItem(wrapInList(nodeType, options.attrs), options)
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
              appNoty('10MB 이하의 파일만 업로드 가능합니다.', 'warning', true).show()
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

function iconByClassName(className) {
  let span = document.createElement("i")
  span.className = className
  return { dom: span }
}

export { buildMenuItems }