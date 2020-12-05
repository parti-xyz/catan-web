function smartFetch(url, options) {
  let headers = new window.Headers()
  let smartOptions = Object.assign({}, {
    headers,
    credentials: 'same-origin',
  }, options)

  if (smartOptions.method && smartOptions.method.toUpperCase() != 'GET') {
    const csrfToken = document.head.querySelector("[name='csrf-token']")
    if (csrfToken) { smartOptions.headers.append('X-CSRF-Token', csrfToken.content) }
  }

  smartOptions.headers.append('X-Requested-With', 'XMLHttpRequest')

  return fetch(url, smartOptions).then(response => {
    if (!response.ok) {
      const event = new CustomEvent('fetch:error', {
        bubbles: true,
        detail: [response],
      })
      document.dispatchEvent(event)

      return null
    }
    return response
  })
}

export { smartFetch }