/* eslint no-console:0 */
import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"

import 'jquery'
import 'popper.js'
import 'bootstrap'
import elementClosest from 'element-closest'
import appNoty from '../helpers/app_noty'

import '../stylesheets/site'

import 'controllers'
import ParamMap from '../helpers/param_map'

Rails.start()
Turbolinks.start()
elementClosest(window)

if (window.jQuery) {
  jQuery(document).on('ajax:success ajax:error', function (event) {
    let [response, status, xhr] = event.detail

    if (xhr.response && xhr.getResponseHeader('X-Force-Remote-Replace-Header') == 'true') {
      const temp = document.createElement('div')
      temp.innerHTML = xhr.response

      let targetElement = event.target
      let parentElement = targetElement.parentNode
      parentElement.replaceChild(temp.firstChild, targetElement)

      parentElement.scrollIntoView({
        behavior: 'smooth'
      })
    }
  })

  function notiFlash(message, status) {
    let flash
    try {
      if (!message) {
        message = null
      }
      flash = JSON.parse(message)
    } catch (e) {
      return
    }

    let reported = false

    if (flash) {
      if (flash.alert) {
        appNoty(decodeURIComponent(escape(flash.alert)), 'warning').show()
        reported = true
      }
      if (flash.notice) {
        appNoty(decodeURIComponent(escape(flash.notice)), 'success').show()
        reported = true
      }
    }

    if (reported) { return }

    if(status == 500) {
      appNoty('뭔가 잘못되었습니다. 곧 고치겠습니다.', 'error', true).show()
    } else if(status == 400) {
      appNoty('요청하신 것을 처리할 수 없습니다.', 'error', true).show()
    } else if(status == 403) {
      appNoty('권한이 없습니다.', 'error', true).show()
    } else if(status == 404) {
      appNoty('어머나! 요청하신 내용이 사라졌어요. 페이지를 새로 고쳐보세요.', 'error', true).show()
    }

    jQuery.each(jQuery('[data-disable-with]'), function (index, elm) { jQuery.rails.enableElement(elm) })
  }

  jQuery(document).on('ajax:success ajax:error', function (event) {
    let [response, status, xhr] = event.detail
    notiFlash(xhr.getResponseHeader('X-Flash-Messages'), xhr.status)
  })

  jQuery(document).on('fetch:error', function (event) {
    let [response] = event.detail
    notiFlash(response.headers.get('X-Flash-Messages'), response.status)
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
            new ParamMap({ identifier: 'simplebar' }, element).set('persistedScrollTop', previousScrollTop)
          }
        }
      }
    })
  })
})()
