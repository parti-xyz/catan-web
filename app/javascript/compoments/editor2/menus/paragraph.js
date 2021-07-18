export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('paragraph')
  }

  click() {
    this.editor.chain().focus().setParagraph().run()
  }
}