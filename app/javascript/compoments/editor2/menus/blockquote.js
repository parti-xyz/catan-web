export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('blockquote')
  }

  click() {
    this.editor.chain().focus().toggleBlockquote().run()
  }
}