const fetchResponseCheck = response => {
  if (!response.ok) {
    const event = new CustomEvent('fetch:error', {
      bubbles: true,
      detail: [response],
    })
    document.dispatchEvent(event)

    return null
  }
  return response
}

const fetchResponseCheckSilent = response => {
  if (!response.ok) {
    return null
  }
  return response
}

export default fetchResponseCheck
export { fetchResponseCheck }