export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('heading', { level: 2 })
  }

  click() {
    this.editor.chain().focus().toggleHeading({ level: 2 }).run()
  }
}