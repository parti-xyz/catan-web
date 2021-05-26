export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('underline')
  }

  click() {
    this.editor.chain().focus().toggleUnderline().run()
  }
}