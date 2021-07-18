export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().splitCell()
  }

  click() {
    this.editor.chain().focus().splitCell().run()
  }
}