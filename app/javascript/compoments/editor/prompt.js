import { TextSelection } from "prosemirror-state"

const CLASS_NAME_PREFIX = "ProseMirror-prompt"

class Prompt {
  constructor(options) {
    this.options = options
    this.open()
  }

  open() {
    this.wrapperElement = document.body.appendChild(document.createElement("div"))
    this.wrapperElement.className = CLASS_NAME_PREFIX

    this.setCloseEvent()
    let submitButton = document.createElement("button")
    submitButton.type = "submit"
    submitButton.className = CLASS_NAME_PREFIX + "-submit"
    submitButton.textContent = "적용"

    let cancelButton = document.createElement("button")
    cancelButton.type = "button"
    cancelButton.className = CLASS_NAME_PREFIX + "-cancel"
    cancelButton.textContent = "취소"
    cancelButton.addEventListener("click", this.closePrompt.bind(this))

    let normalButtonGroup = document.createElement("div")
    normalButtonGroup.className = CLASS_NAME_PREFIX + "-buttongroup"
    normalButtonGroup.appendChild(cancelButton)
    normalButtonGroup.appendChild(document.createTextNode(" "))
    normalButtonGroup.appendChild(submitButton)

    let sepecialButtonGroup = document.createElement("div")
    sepecialButtonGroup.className = CLASS_NAME_PREFIX + "-buttongroup"
    let removeButton
    if (this.options.onDestroy) {
      removeButton = document.createElement("button")
      removeButton.type = "button"
      removeButton.className = CLASS_NAME_PREFIX + "-remove"
      removeButton.textContent = "제거"
      removeButton.addEventListener("click", this.removeHandle.bind(this))

      sepecialButtonGroup.appendChild(removeButton)
    }

    let formElement = this.wrapperElement.appendChild(document.createElement("form"))
    if (this.options.title) {
      formElement.appendChild(document.createElement("h5")).textContent = this.options.title
    }

    let fieldElements = []
    for (let name in this.options.fields) {
      const field = this.options.fields[name]
      const fieldElement = field.render(name)
      fieldElements.push(fieldElement)
      formElement.appendChild(this.renderFromGruop(fieldElement, field.options.label))
    }

    let buttons = formElement.appendChild(document.createElement("div"))
    buttons.className = CLASS_NAME_PREFIX + "-buttongroups"
    buttons.appendChild(sepecialButtonGroup)
    buttons.appendChild(normalButtonGroup)

    let box = this.wrapperElement.getBoundingClientRect()
    this.wrapperElement.style.top = ((window.innerHeight - box.height) / 2) + "px"
    this.wrapperElement.style.left = ((window.innerWidth - box.width) / 2) + "px"

    formElement.addEventListener("submit", event => {
      event.preventDefault()
      this.submitHandle(fieldElements)
    })

    formElement.addEventListener("keydown", event => {
      if (event.keyCode == 27) {
        event.preventDefault()
        this.closePrompt()
      } else if (event.keyCode == 13 && !(event.ctrlKey || event.metaKey || event.shiftKey)) {
        event.preventDefault()
        this.submitHandle(fieldElements)
      } else if (event.keyCode == 9) {
        window.setTimeout(() => {
          if (!this.wrapperElement.contains(document.activeElement)) { this.closePrompt() }
        }, 500)
      }
    })
    const firstFieldElement = fieldElements[0]
    if (firstFieldElement) { firstFieldElement.focus() }
  }

  removeHandle(event) {
    this.closePrompt()
    this.options.onDestroy()
  }

  mouseOutside(event) {
    if (this.wrapperElement && !this.wrapperElement.contains(event.target)) { this.closePrompt() }
  }

  closePrompt() {
    if (this.closeHandler) {
      window.removeEventListener("mousedown", this.closeHandler)
      this.closeHandler = null
    }
    if (this.wrapperElement && this.wrapperElement.parentNode) {
      this.wrapperElement.parentNode.removeChild(this.wrapperElement)
    }
  }

  setCloseEvent() {
    setTimeout(() => {
      if (!this.closeHandler) {
        this.closeHandler = this.mouseOutside.bind(this)
      }
      return window.addEventListener("mousedown", this.closeHandler)
    }, 50)
  }

  submitHandle(fieldElements) {
    let params = this.getValues(this.options.fields, fieldElements)
    if (params) {
      this.closePrompt()
      this.options.onSave(params)
    }
  }

  getValues(fields, fieldElements) {
    let result = {}, i = 0;
    for (let name in fields) {
      let field = fields[name], dom = fieldElements[i++];
      let value = field.read(dom), bad = field.validate(value);
      if (bad) {
        this.reportInvalid(dom, bad);
        return null
      }
      result[name] = field.clean(value);
    }
    return result
  }

  reportInvalid(dom, message) {
    let parent = dom.parentNode;
    let msg = parent.appendChild(document.createElement("div"));
    msg.style.left = (dom.offsetLeft + dom.offsetWidth + 2) + "px";
    msg.style.top = (dom.offsetTop - 5) + "px";
    msg.className = "ProseMirror-invalid";
    msg.textContent = message;
    setTimeout(function () { return parent.removeChild(msg); }, 1500);
  }

  renderFromGruop(fieldElement, label) {
    let formGroup = document.createElement("div")
    formGroup.className = CLASS_NAME_PREFIX + "-formgroup"

    if (label) {
      let labelElement = document.createElement("label")
      labelElement.textContent = label
      labelElement.classList.add(CLASS_NAME_PREFIX + "-label")
      formGroup.appendChild(labelElement)
    }

    fieldElement.classList.add(CLASS_NAME_PREFIX + "-field")
    formGroup.appendChild(fieldElement)
    return formGroup
  }
}

class Field {
  constructor(options) {
    this.options = options
  }

  read(dom) {
    return dom.value
  }

  validate(value) {
    if (!value && this.options.required) { return "값을 입력해 주세요" }
    return this.options.validate && this.options.validate(value)
  }

  clean(value) {
    return this.options.clean ? this.options.clean(value) : value
  }
}

class TextField extends Field {
  render(name) {
    let input = document.createElement("input")
    input.type = "text"
    input.name = name
    input.value = this.options.value || ""
    input.autocomplete = "off"
    return input
  }
}

export { Prompt, TextField }