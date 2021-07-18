export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().addColumnAfter()
  }

  click() {
    this.editor.chain().focus().addColumnAfter().run()
  }
}