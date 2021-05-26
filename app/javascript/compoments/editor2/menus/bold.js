export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('bold')
  }

  click() {
    this.editor.chain().focus().toggleBold().run()
  }
}