export default class {
  constructor(editor) {
    this.editor = editor
  }

  isActive() {
    return this.editor.isActive('bulletList')
  }

  click() {
    this.editor.chain().focus().toggleBulletList().run()
  }
}
//https://github.com/ueberdosis/tiptap/issues/1036#issue-864043820