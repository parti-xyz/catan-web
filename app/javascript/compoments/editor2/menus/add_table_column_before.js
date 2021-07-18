export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().addColumnBefore()
  }

  click() {
    this.editor.chain().focus().addColumnBefore().run()
  }
}