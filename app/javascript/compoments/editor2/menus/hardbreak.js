export default class {
  constructor(editor) {
    this.editor = editor
  }

  click() {
    this.editor.chain().focus().setHardBreak().run()
  }
}