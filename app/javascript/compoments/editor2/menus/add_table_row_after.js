export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().addRowAfter()
  }

  click() {
    this.editor.chain().focus().addRowAfter().run()
  }
}