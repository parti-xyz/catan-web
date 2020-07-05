import { Controller } from 'stimulus'

export default class extends Controller {
  initialize() {
    this.forceDirty = false
  }

  connect() {
    this.setInitialValues(this.element)
    this.setFormEvents(this.element)
    this.forceDirty = false
  }

  disconnect() {
    this.unsetInitialValues(this.element)
    this.unsetFormEvents(this.element)
    this.forceDirty = false
  }

  setInitialValues(form) {
    form.dataset.dirtyFormIsDirty = 'false'

    form.querySelectorAll("input, select, textarea").forEach(control => {
      control.dataset.dirtyFormInitialValue = control.value
    })

    form.querySelectorAll("input[type=checkbox], input[type=radio]").forEach(control => {
      control.dataset.dirtyFormInitialValue = control.checked ? 'checked' : 'unchecked'
    })
  }

  unsetInitialValues(form) {
    form.dataset.dirtyFormIsDirty = 'false'

    form.querySelectorAll("input, select, textarea").forEach(control => {
      control.dataset.dirtyFormInitialValue = null
    })

    form.querySelectorAll("input[type=checkbox], input[type=radio]").forEach(control => {
      control.dataset.dirtyFormInitialValue = null
    })
  }

  setFormEvents(form) {
    form.addEventListener('submit', this.submit.bind(this))
    form.addEventListener('ajax:before', this.submit.bind(this))
    form.addEventListener('dirty-form:submit', this.submit.bind(this))

    form.querySelectorAll("input, select").forEach(control => {
      control.addEventListener('change', this.checkValues.bind(this))
    })

    form.querySelectorAll("input, textarea").forEach(control => {
      ['keyup', 'keydown', 'blur'].forEach(eventKey => {
        control.addEventListener(eventKey, this.checkValues.bind(this))
      })
    })
  }

  unsetFormEvents(form) {
    form.removeEventListener('submit', this.submit.bind(this))
    form.removeEventListener('ajax:before', this.submit.bind(this))

    form.querySelectorAll("input, select").forEach(control => {
      control.removeEventListener('change', this.checkValues.bind(this))
    })

    form.querySelectorAll("input, textarea").forEach(control => {
      ['keyup', 'keydown', 'blur'].forEach(eventKey => {
        control.removeEventListener(eventKey, this.checkValues.bind(this))
      })
    })
  }

  submit(event) {
    let form = event.target
    form.dataset.dirtyFormIsDirty = 'false'

    form.querySelectorAll("input, select, textarea").forEach(control => {
      control.dataset.dirtyFormInitialValue = control.value
      control.dataset.dirtyFormIsDirty = 'false'
    })
  }

  checkValues(event) {
    let form = event.target.closest('form')
    if (!form) { return }

    form.querySelectorAll("input, select, textarea").forEach(control => {
      let initialValue = control.dataset.dirtyFormInitialValue

      control.dataset.dirtyFormIsDirty = (control.value == initialValue ? 'false' : 'true')
    })

    form.querySelectorAll("input[type=checkbox], input[type=radio]").forEach(control => {
      let initialValue = control.dataset.dirtyFormInitialValue

      if (control.checked && initialValue != "checked"
        || !control.checked && initialValue == "checked") {
        control.dataset.dirtyFormIsDirty = 'true'
      } else {
        control.dataset.dirtyFormIsDirty = 'false'
      }
    })

    let isDirty = this.forceDirty || Array.from(form.querySelectorAll("input, select, textarea")).some(control => {
      return control.dataset.dirtyFormIsDirty == 'true'
    })

    form.dataset.dirtyFormIsDirty = isDirty ? 'true' : 'false'
  }

  setForceDirty(event) {
    this.forceDirty = true
    this.checkValues(event)
  }
}