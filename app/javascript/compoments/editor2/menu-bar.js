export default class MenuBar {
  constructor(editor, menuBarWrapperTarget, menuBarTarget, menuBarSpacerTarget, menuTargets) {
    this.wrapperElement = menuBarWrapperTarget
    this.menuBarElement = menuBarTarget
    this.spacerElement = menuBarSpacerTarget

    this.initMenus(editor, menuTargets)
    this.initFloating(editor)
  }

  initMenus(editor, menuTargets) {
    this.menus = new Map()

    menuTargets.forEach(menuTarget => {
      const menuName = menuTarget.dataset.menuName
      import(/* webpackMode: "eager" */ `./menu/${menuName}`).then(Menu => {
        const menu = new Menu.default(editor)

        const onMenuUpdate = (target) => {
          menuTarget.classList.add('border-0')
          if (menu.isActive()) {
            menuTarget.classList.add('btn-dark')
            menuTarget.classList.remove('btn-outline-dark')
          } else {
            menuTarget.classList.remove('btn-dark')
            menuTarget.classList.add('btn-outline-dark')
          }
        }
        editor.on('selectionUpdate', onMenuUpdate)
        editor.on('transaction', onMenuUpdate)

        this.menus.set(menuName, menu)
      })
    })
  }

  initFloating(editor) {
    this.floating = false

    if (!this.isIOS()) {
      this.updateFloat()
      let potentialScrollers = this.getAllWrapping(this.wrapperElement)
      this.handleScroll = (e) => {
        let root = editor.view.root
        if (!(root.body || root).contains(this.wrapperElement)) {
            potentialScrollers.forEach(el => el.removeEventListener("scroll", this.handleScroll))
        } else {
            this.updateFloat(e.target.getBoundingClientRect && e.target)
        }
      }
      potentialScrollers.forEach(el => el.addEventListener('scroll', this.handleScroll))
    }
  }

  handleClick(event) {
    const menuName = event.currentTarget.dataset.menuName
    const menu = this.menus.get(menuName)
    if (!menu) { return }

    event && event.preventDefault()
    menu.click()
  }

  updateFloat(scrollAncestor) {
    let parent = this.wrapperElement,
        editorRect = parent.getBoundingClientRect(),
        top = scrollAncestor ? Math.max(0, scrollAncestor.getBoundingClientRect().top) : 0

    if (this.floating) {
      if (editorRect.top >= top || editorRect.bottom < this.menuBarElement.offsetHeight + 10) {
        this.floating = false
        this.menuBarElement.style.position = this.menuBarElement.style.left = this.menuBarElement.style.top = this.menuBarElement.style.width = ''
        this.menuBarElement.style.display = ''
        this.spacerElement.style.display = 'none'
      } else {
        let border = (parent.offsetWidth - parent.clientWidth) / 2
        this.menuBarElement.style.left = (editorRect.left + border) + 'px'
        this.menuBarElement.style.display = (editorRect.top > window.innerHeight ? 'none' : '')
        if (scrollAncestor) this.menuBarElement.style.top = top + 'px'
      }
    } else {
      if (editorRect.top < top && editorRect.bottom >= this.menuBarElement.offsetHeight + 10) {
        this.floating = true
        let menuRect = this.menuBarElement.getBoundingClientRect()
        this.menuBarElement.style.left = menuRect.left + 'px'
        this.menuBarElement.style.width = menuRect.width + 'px'
        if (scrollAncestor) this.menuBarElement.style.top = top + 'px'
        this.menuBarElement.style.position = 'fixed'
        this.spacerElement.style.height = menuRect.height + 'px'
        this.spacerElement.style.display = `block`
      }
    }
  }

  getAllWrapping(node) {
    let res = [window]
    for (let cur = node.parentNode; cur; cur = cur.parentNode)
        res.push(cur)
    return res
  }

  isIOS() {
    if (typeof navigator == "undefined") return false
    let agent = navigator.userAgent
    return !/Edge\/\d/.test(agent) && /AppleWebKit/.test(agent) && /Mobile\/\w+/.test(agent)
  }
}