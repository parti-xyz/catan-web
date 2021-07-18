export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().addRowBefore()
  }

  click() {
    this.editor.chain().focus().addRowBefore().run()
  }
}