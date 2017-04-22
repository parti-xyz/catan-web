(function (document) {
  'use strict';

  /**
   * Test webP images support.
   * @param {Function} callback - Callback function.
   */
  var testWepP = function testWepP(callback) {
    var webP = new Image();

    webP.src = 'data:image/webp;base64,UklGRi4AAABXRUJQVlA4TCEAAAAvAUAAEB8wA' + 'iMwAgSSNtse/cXjxyCCmrYNWPwmHRH9jwMA';
    webP.onload = webP.onerror = function () {
      callback(webP.height === 2);
    };
  };

  /**
   * Add 'webp' class to body if supported.
   * @param {Boolean} support - WebP format support.
   */
  var addWebPClass = function addWebPClass(support) {
    if (support) {
      var el = document.body;

      if (el.classList) {
        el.classList.add('webp');
      } else {
        el.className += ' webp';
      }
    } else {
      var el = document.body;

      if (el.classList) {
        el.classList.add('no-webp');
      } else {
        el.className += ' no-webp';
      }
    }
  };

  document.addEventListener('DOMContentLoaded', testWepP(function(support) { addWebPClass(support); }));
})(document);
