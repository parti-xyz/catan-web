export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().deleteColumn()
  }

  click() {
    this.editor.chain().focus().deleteColumn().run()
  }
}