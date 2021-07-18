export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().deleteRow()
  }

  click() {
    this.editor.chain().focus().deleteRow().run()
  }
}