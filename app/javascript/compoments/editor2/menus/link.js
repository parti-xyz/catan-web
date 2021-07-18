import { Prompt, TextField } from '../prompt'
import getValidUrl from '../../../helpers/valid_url'

export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('link')
  }

  click() {
    const { href } = this.editor.getAttributes('link')
    new Prompt({
      title: "링크 걸기",
      fields: {
        href: new TextField({
          label: "주소",
          value: href,
          required: true,
        })
      },
      onSave: (params) => {
        if (!params.href || params.href.length <= 0) {
          appNoti('주소를 입력해 주세요.', 'warning')
          return false
        }
        params.href = getValidUrl(params.href)
        this.editor.chain().focus().setLink(params).run()
        return true
      },
      onDestroy: this.isActive() ? ((attrs) => {
        this.editor.chain().focus().unsetLink().run()
      }) : undefined
    })
  }
}