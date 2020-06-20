import Noty from 'noty'

const appNoty = (text, type, modal = false) => {
  return new Noty({
    type: type || 'warning',
    text: text,
    timeout: 3000,
    modal: modal,
    theme: 'bootstrap-v4',
    closeWith: ['button', 'click']
  })
}

export default appNoty