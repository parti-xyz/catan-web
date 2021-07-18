export default class {
  constructor(editor) {
    this.editor = editor
  }

  isHidden() {
    // return !this.editor.isActive('bulletList') && !this.editor.isActive('orderedList')
    return !this.editor.can().liftListItem('listItem')
  }

  click() {
    this.editor.chain().focus().liftListItem('listItem').run()
  }
}