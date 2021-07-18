export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().toggleHeaderColumn()
  }

  click() {
    this.editor.chain().focus().toggleHeaderColumn().run()
  }
}