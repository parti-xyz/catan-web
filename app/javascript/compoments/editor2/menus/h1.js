export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    console.log(this.editor.isActive('heading', { level: 1 }))
    return this.editor.isActive('heading', { level: 1 })
  }

  click() {
    this.editor.chain().focus().toggleHeading({ level: 1 }).run()
  }
}