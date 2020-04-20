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

import '../stylesheets/site'

import 'controllers'

Rails.start()
Turbolinks.start()

$(document).ready(function () {
  $('body').tooltip({
    selector: '[data-toggle="tooltip"]'
  })
});

(function () {
  const scrollTops = new Map

  function findElements() {
    return document.querySelectorAll("[data-turbolinks-scroll-persistence]")
  }

  function simplebarElement(element) {
    return element.querySelector(':scope > .simplebar-wrapper > .simplebar-mask > .simplebar-offset > .simplebar-content-wrapper')
  }

  addEventListener("turbolinks:before-render", function () {
    findElements().forEach(function (element) {
      if (element.id) {
        const simplebar = simplebarElement(element)
        const scrollTop = simplebar ? simplebar.scrollTop : element.scrollTop

        scrollTops.set(element.id, scrollTop)
      }
    })
  })

  addEventListener("turbolinks:render", function () {
    findElements().forEach(function (element) {
      if (scrollTops.has(element.id)) {
        const simplebar = simplebarElement(element)
        const scrollableElement = simplebar ? simplebar : element

        scrollableElement.scrollTop = scrollTops.get(element.id)
      }
    })
  })


})()
