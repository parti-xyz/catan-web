import { Prompt, TextField, ImageFileField } from '../prompt'
import getValidUrl from '../../../helpers/valid_url'
import { startImageUpload } from '../plugins/image_upload_plugin'

export default class {
  constructor(editor, element) {
    this.editor = editor
    this.ruleFileSize = element.dataset.menuOptionRuleFileSize
    this.uploadUrl = element.dataset.menuOptionUploadUrl
  }

  isActive() {
    return this.editor.isActive('image')
  }

  click() {
    new Prompt({
      title: "이미지 선택",
      fields: {
        file: new ImageFileField({ label: "선택", required: true, }),
      },
      onSave: this.onUpload.bind(this),
    })
  }

  onUpload(params) {
    this.editor.chain().focus().run()

    if (!params.file || !params.file[0]) return
    if (!this.uploadUrl) return

    const currentFile = params.file[0]
    if (this.ruleFileSize && this.ruleFileSize < currentFile.size) {
      appNoty('25MB 이하의 파일만 업로드 가능합니다.', 'warning', true).show()
      return
    }

    startImageUpload(this.editor.view, currentFile, this.uploadUrl)
    return true
  }
}