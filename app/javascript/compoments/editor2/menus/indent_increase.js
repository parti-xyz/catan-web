export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    return !this.editor.can().sinkListItem('listItem')
  }

  click() {
    this.editor.chain().focus().sinkListItem('listItem').run()
  }
}