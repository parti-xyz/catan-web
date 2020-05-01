/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"

import 'jquery'
import 'popper.js'
import 'bootstrap'
import elementClosest from 'element-closest'

import '../stylesheets/site'

import 'controllers'

elementClosest(window)
Rails.start()
Turbolinks.start()

$(document).ready(function () {
  $('body').tooltip({
    selector: '[data-toggle="tooltip"]'
  })
});

(function () {
  const _scrollDataMaps = new Map()

  function findElements() {
    return document.querySelectorAll("[data-js~=scroll-persistence]")
  }

  function simplebarElement(element) {
    return element.querySelector(':scope > .simplebar-layout > .simplebar-wrapper > .simplebar-mask > .simplebar-offset > .simplebar-content-wrapper')
  }

  addEventListener("turbolinks:before-cache", function () {
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

  addEventListener("turbolinks:render", function () {
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
            element.dataset.jsScrollPersistenceScrollTop = previousScrollTop
          }
        }
      }
    })
  })


})()
