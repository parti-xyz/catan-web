import Noty from 'noty'

const appNoty = (text, type, modal = false) => {
  new Noty({
    type: type || 'warning',
    text: text,
    timeout: 3000,
    modal: modal,
    closeWith: ['button', 'click']
  }).show()
}

export default appNoty