export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('orderedList')
  }

  click() {
    this.editor.chain().focus().toggleOrderedList().run()
  }
}
//https://github.com/ueberdosis/tiptap/issues/1036#issue-864043820