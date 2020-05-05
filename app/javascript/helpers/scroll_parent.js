const regex = /(auto|scroll)/

const style = (node, prop) =>
  getComputedStyle(node, null).getPropertyValue(prop)

const scroll = (node) =>
  regex.test(
    style(node, "overflow") +
    style(node, "overflow-y") +
    style(node, "overflow-x"))

const scrollParent = (node) =>
  !node || node === document.body
    ? document.body
    : scroll(node)
      ? node
      : scrollParent(node.parentNode)

export default scrollParent