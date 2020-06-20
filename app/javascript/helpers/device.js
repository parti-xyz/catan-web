const isTouchDevice = () => {
  return ("ontouchstart" in window) || window.DocumentTouch && document instanceof DocumentTouch
}

export { isTouchDevice }