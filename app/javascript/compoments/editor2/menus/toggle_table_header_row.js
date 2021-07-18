export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().toggleHeaderRow()
  }

  click() {
    this.editor.chain().focus().toggleHeaderRow().run()
  }
}