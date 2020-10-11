import { Controller } from "stimulus"
import appNoty from '../helpers/app_noty'

const validityMessages = {
  badInput: '잘못된 입력입니다.',
  patternMismatch: '형식엔 맞게 입력하세요.',
  rangeOverflow: '값이 너무 큽니다.',
  rangeUnderflow: '값이 너무 작습니다.',
  stepMismatch: '숫자 형식에 맞지 않습니다.',
  tooLong: '입력한 값이 너무 깁니다.',
  tooShort: '입력한 값이 너무 짧습니다.',
  typeMismatch: '형식에 맞게 입력하세요.',
  valueMissing: '값을 반드시 입력하세요.',
}

const validateAttributes = ['pattern', 'required', 'minlength', 'maxlength']

export default class extends Controller {
  static targets = ['editorHtml']

  connect() {
    this.clearValidationReportHandler = this.clearValidationReport.bind(this)
    this.element.addEventListener('editor-form:focus', this.clearValidationReportHandler)
  }

  disconnect() {
    if (this.clearValidationReportHandler) {
      this.element.removeEventListener('editor-form:focus', this.clearValidationReportHandler)
    }
  }

  submit(event) {
    let stopped = false

    this.clearValidationReport()

    this.editorHtmlTargets.forEach(editorHtmlTarget => {
      let tempContent = document.createElement('div')
      tempContent.innerHTML = this.editorHtmlTarget.value
      let editorHtml = tempContent.textContent

      let tempInputElement = document.createElement('input')
      tempInputElement.setAttribute('type', 'text')

      validateAttributes.forEach(attributeName => {
        let textAttributeName = 'text' + attributeName
        if (!editorHtmlTarget.hasAttribute(textAttributeName)) {
          return
        }

        tempInputElement.setAttribute(attributeName, editorHtmlTarget.getAttribute(textAttributeName))
      })
      tempInputElement.value = editorHtml

      if (tempInputElement.checkValidity() === false) {
        this.showValidationReport(editorHtmlTarget, tempInputElement)
        editorHtmlTarget.classList.add('is-invalid')
        if (!stopped) {
          this.stopSubmit()
          stopped = true
        }
      }
    })

    if (this.element.checkValidity() === false) {
      let invalidElements = this.element.querySelectorAll(':invalid')
      Array.from(invalidElements).forEach(invalidElement => {
        if (this.invisible(invalidElement)) { return }

        this.showValidationReport(invalidElement)
        if (!stopped) {
          this.stopSubmit()
          stopped = true
        }
      })
    }

    if (stopped) {
      appNoty('입력한 값을 확인하고 다시 시도해 주세요.', 'warning', true).show()
    }
  }

  stopSubmit() {
    event.preventDefault()
    event.stopPropagation()

    setTimeout(function () {
      this.element.querySelectorAll('[data-disable-with]').forEach(el => jQuery.rails.enableElement(el))
    }.bind(this), 1000)
  }

  showValidationReport(invalidElement, proxyElement = invalidElement) {
    let messageDataset = invalidElement.dataset
    invalidElement.insertAdjacentHTML('afterEnd', this.getFullMessagesTooltip(proxyElement, messageDataset))
    invalidElement.parentNode.classList.add('was-validated')
    invalidElement.parentNode.classList.add('position-relative')
  }

  getFullMessagesTooltip(invalidElement, messageDataset) {
    let messages = Object.keys(validityMessages).map(key => {
      if (!invalidElement.validity[key]) { return }

      let message = messageDataset[key + 'Message']
      if (message) { return message }

      message = validityMessages[key]
      if (message) { return message }

      return '값을 다시 확인해 주세요.'
    }).filter(message => message)

    messages = messages.filter((item, index) => messages.indexOf(item) === index)

    return `
      <div class="invalid-tooltip" data-validate-form-invalid-tooltip>
        ${messages.join('<br>')}
      </div>
    `
  }

  clearValidationReport() {
    let messagsTooltips = this.element.querySelectorAll('[data-validate-form-invalid-tooltip]')
    Array.from(messagsTooltips).forEach(messagsTooltip => {
      messagsTooltip.remove()
    })

    let wasValidatedElements = this.element.querySelectorAll('.was-validated')
    Array.from(wasValidatedElements).forEach(wasValidatedElement => {
      wasValidatedElement.classList.remove('was-validated')
    })
  }

  invisible(element) {
    return !(element.offsetWidth || element.offsetHeight || element.getClientRects().length)
  }
}