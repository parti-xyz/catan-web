export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('heading', { level: 1 })
  }

  click() {
    this.editor.chain().focus().toggleHeading({ level: 1 }).run()
  }
}