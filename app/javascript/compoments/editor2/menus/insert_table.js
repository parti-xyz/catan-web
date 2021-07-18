export default class {
  constructor(editor) {
    this.editor = editor
  }

  click() {
    this.editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
  }
}