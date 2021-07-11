export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().deleteTable()
  }

  click() {
    this.editor.chain().focus().deleteTable().run()
  }
}