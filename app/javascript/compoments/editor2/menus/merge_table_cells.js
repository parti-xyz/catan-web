export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().mergeCells()
  }

  click() {
    this.editor.chain().focus().mergeCells().run()
  }
}