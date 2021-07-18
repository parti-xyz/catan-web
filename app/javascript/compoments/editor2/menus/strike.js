export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('strike')
  }

  click() {
    this.editor.chain().focus().toggleStrike().run()
  }
}