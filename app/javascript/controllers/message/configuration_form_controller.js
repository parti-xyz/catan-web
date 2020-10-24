import { Controller } from 'stimulus'
import { smartFetch } from '../../helpers/smart_fetch'

export default class extends Controller {
  static targets = ['payoffInput']
  connect() {
    this.payoffValues = {}
    this.element.elements.forEach(input => {
      this.payoffValues[input.name] = input.value
      input.addEventListener('change', (event) => {
        this.save(input)
      })
    })
  }

  disconnect() {
    this.payoffValues = null
  }

  save(targetInput) {
    let formData = new FormData()
    let filterdInputs = Array.from(this.element.elements).filter(currentInput => {
      return !this.payoffInputTargets.includes(currentInput) || currentInput == targetInput
    })
    filterdInputs.forEach(currentInput => {
      formData.append(currentInput.name, currentInput.value)
    })

    targetInput.classList.add('collapse', 'hide')

    let spinner = document.createElement('div')
    spinner.innerHTML = '<span><i class="fa fa-spinner fa-pulse"></i>&nbsp;저장 중...</span>'
    targetInput.parentNode.insertBefore(spinner, targetInput)

    smartFetch(this.element.getAttribute("action"), {
      method: this.element.getAttribute("method"),
      body: formData,
    }).then(response => {
      this.payoffValues[targetInput.name] = targetInput.value
      spinner.classList.add('fade-out-base')
    }).catch(e => {
      targetInput.value = this.payoffValues[targetInput.name]
      spinner.innerHTML = '<span class="d-inline-block  align-middle"><i class="fa fa-check"></i>&nbsp;저장 실패</span>'
      spinner.classList.add('fade-out-base')
    }).finally(() => {
      setTimeout(() => {
        spinner.remove()
        targetInput.classList.remove('collapse', 'hide')
      }, 1500)
    })

  }
}