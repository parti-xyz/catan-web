// https://github.com/ueberdosis/tiptap/blob/2c48bc09eac3f3ed65e01d7b7efd37984534db91/docs/src/docPages/guide/custom-extensions.md
import Image from '@tiptap/extension-image'

export const ResizableImage = Image.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      width: {
        default: "10em",
        renderHTML: attributes => {
          return {
            width: attributes.width,
            style: `width: ${attributes.width}`,
          }
        },
      },
    }
  },
  addNodeView() {
    return ({
      node,
      HTMLAttributes,
      getPos,
      editor,
    }) => {
      const container = document.createElement("span")

      container.style.position = "relative"
      container.style.width = node.attrs.width
      container.style.display = "inline-block"
      container.style.lineHeight = "0"; // necessary so the bottom right arrow is aligned nicely

      const img = document.createElement("img")
      img.setAttribute("src", node.attrs.src)
      img.style.width = "100%"
      img.style.border = "1px solid #f6f8fa"

      const handle = document.createElement("span")
      handle.style.position = "absolute"
      handle.style.bottom = "0px"
      handle.style.right = "0px"
      handle.style.width = "10px"
      handle.style.height = "10px"
      handle.style.border = "3px solid black"
      handle.style.borderTop = "none"
      handle.style.borderLeft = "none"
      handle.style.display = "none"
      handle.style.cursor = "nwse-resize"

      handle.onmousedown = function (e) {
        e.preventDefault()

        const startX = e.pageX;
        const startY = e.pageY;

        const fontSize = parseFloat(getComputedStyle(container).fontSize)
        const startWidth = parseFloat(container.style.width.match(/(.+)em/)[1])

        const onMouseMove = (e) => {
          const currentX = e.pageX;
          const currentY = e.pageY;

          const diffInPx = currentX - startX
          const diffInEm = diffInPx / fontSize

          container.style.width = `${startWidth + diffInEm}em`
        }

        const onMouseUp = (e) => {
          e.preventDefault()

          document.removeEventListener("mousemove", onMouseMove)
          document.removeEventListener("mouseup", onMouseUp)

          const transaction = editor.view.state.tr.setNodeMarkup(getPos(), null, { src: node.attrs.src, width: container.style.width })

          transaction.setSelection(editor.view.state.selection.map(transaction.doc, transaction.mapping))

          editor.view.dispatch(transaction)

          node.attrs.width = container.style.width
        }

        document.addEventListener("mousemove", onMouseMove)
        document.addEventListener("mouseup", onMouseUp)
      }

      container.appendChild(handle)
      container.appendChild(img)

      return {
        dom: container,
        selectNode: () => {
          img.classList.add("ProseMirror-selectednode")
          handle.style.display = ""
        },
        deselectNode() {
          img.classList.remove("ProseMirror-selectednode")
          handle.style.display = "none"
        },
      }
    }
  },
})