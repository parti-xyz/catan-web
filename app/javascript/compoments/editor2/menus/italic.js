export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('italic')
  }

  click() {
    this.editor.chain().focus().toggleItalic().run()
  }
}