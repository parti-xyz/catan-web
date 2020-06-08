/* eslint no-console:0 */
import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"

import 'jquery'
import 'popper.js'
import 'bootstrap'
import elementClosest from 'element-closest'
import Noty from 'noty'

import '../stylesheets/site'

import 'controllers'
import ParamMap from '../helpers/param_map'

Rails.start()
Turbolinks.start()
elementClosest(window)

if (window.jQuery) {
  jQuery(document).ready(function($) {
    $('body').tooltip({
      selector: '[data-toggle="tooltip"]',
    })
  })

  jQuery(document).on('ajax:success ajax:error', function (event) {
    let [response, status, xhr] = event.detail

    if (xhr.response && xhr.getResponseHeader('X-Force-Remote-Replace-Header') == 'true') {
      const temp = document.createElement('div')
      temp.innerHTML = xhr.response

      let targetElement = event.target
      targetElement.parentNode.replaceChild(temp.firstChild, targetElement)
    }

    let flash = null
    try {
      flash = JSON.parse(xhr.getResponseHeader('X-Flash-Messages'))
    } catch(e) {
      return
    }
    let reported = false

    if (flash) {
      if (flash.alert) {
        new Noty({
          type: 'warning',
          text: decodeURIComponent(escape(flash.alert)),
          timeout: 3000,
        }).show()
        reported = true
      }
      if (flash.notice) {
        new Noty({
          type: 'success',
          text: decodeURIComponent(escape(flash.notice)),
          timeout: 3000,
        }).show()
        reported = true
      }
    }

    if (reported) { return }

    if(xhr.status == 500) {
      new Noty({
        type: 'error',
        text: decodeURIComponent('뭔가 잘못되었습니다. 곧 고치겠습니다.'),
        timeout: 3000,
      }).show()
    } else if(xhr.status == 400) {
      new Noty({
        type: 'error',
        text: decodeURIComponent('요청하신 것을 처리할 수 없습니다.'),
        timeout: 3000,
      }).show()
    } else if(xhr.status == 403) {
      new Noty({
        type: 'error',
        text: decodeURIComponent('권한이 없습니다.'),
        timeout: 3000,
      }).show()
    } else if(xhr.status == 404) {
      new Noty({
        type: 'error',
        text: decodeURIComponent('어머나! 요청하신 내용이 사라졌어요. 페이지를 새로 고쳐보세요.'),
        timeout: 3000,
      }).show()
    }

    $.each($('[data-disable-with]'), function(index, elm) { $.rails.enableElement(elm) })
  })
}

(function() {
  const _scrollDataMaps = new Map()

  function findElements() {
    return document.querySelectorAll("[data-js~=scroll-persistence]")
  }

  function simplebarElement(element) {
    return element.querySelector(':scope > .simplebar-layout > .simplebar-wrapper > .simplebar-mask > .simplebar-offset > .simplebar-content-wrapper')
  }

  document.addEventListener("turbolinks:before-cache", function () {
    findElements().forEach(function (element) {
      const scrollPersistenceId = element.dataset.scrollPersistenceId
      if (scrollPersistenceId) {
        const simplebar = simplebarElement(element)
        const scrollTop = simplebar ? simplebar.scrollTop : element.scrollTop

        const scrollPersistenceTag = element.dataset.scrollPersistenceTag
        _scrollDataMaps.set(scrollPersistenceId, { scrollTop: scrollTop, tag: scrollPersistenceTag })
      }
    })
  })

  document.addEventListener("turbolinks:render", function () {
    findElements().forEach(function (element) {
      const scrollPersistenceId = element.dataset.scrollPersistenceId
      if (scrollPersistenceId && _scrollDataMaps.has(scrollPersistenceId)) {
        const simplebar = simplebarElement(element)
        const scrollElement = simplebar ? simplebar : element

        const scrollData = _scrollDataMaps.get(scrollPersistenceId)
        const previousScrollTop = scrollData.scrollTop
        const scrollPersistenceTag = element.dataset.scrollPersistenceTag

        if (scrollData.tag === scrollPersistenceTag) {
          scrollElement.scrollTop = previousScrollTop
          if (previousScrollTop != scrollElement.scrollTop) {
            new ParamMap({ identifier: 'simplebar' }, element).set('presistedScrollTop', previousScrollTop)
          }
        }
      }
    })
  })
})()
