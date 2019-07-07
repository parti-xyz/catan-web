/*
 * Viewport - jQuery selectors for finding elements in viewport
 *
 * Copyright (c) 2008-2009 Mika Tuupola
 *
 * Licensed under the MIT license:
 *   http://www.opensource.org/licenses/mit-license.php
 *
 * Project home:
 *  http://www.appelsiini.net/projects/viewport
 *
 * Clean up by Rick Waldron, 2010
 *
 * Includes:
 *
 * - Consolidation of functions into single fn namespace
 * - Filter functions declared within an object
 * - caching of multiple repetitive $(window) calls to $window
 * - caching of multiple repetitive $(element) calls to $element
 *
 */
(function($) {

    //  declare and assign a single fn namespace
    $.viewport  = function ( expr, element, settings ) {
      // privately declare all custom viewport fns
      var viewables = {
        belowthefold: function(element, settings) {
          var $window = $(window),
              fold    = $window.height() + $window.scrollTop();

          return fold <= $(element).offset().top - settings.threshold;
        },
        abovethetop: function(element, settings) {
          var $window   = $(window),
              $element  = $(element),
              top       = $window.scrollTop();

          return top >= $element.offset().top + $element.height() - settings.threshold;
        },
        rightofscreen: function(element, settings) {
          var $window   = $(window),
              $element  = $(element),
              fold      = $window.width() + $window.scrollLeft();

          return fold <= $element.offset().left - settings.threshold;
        },
        leftofscreen: function(element, settings) {
          var $window   = $(window),
              $element  = $(element),
              left      = $window.scrollLeft();

          return left >= $element.offset().left + $element.width() - settings.threshold;
        },
        inviewport: function(element, settings) {
          return !$.viewport('rightofscreen', element, settings) &&
                  !$.viewport('leftofscreen', element, settings) &&
                    !$.viewport('belowthefold', element, settings) &&
                      !$.viewport('abovethetop', element, settings);
        }
      };

      if ( viewables[expr] && $.isFunction(viewables[expr]) ) {
        return viewables[expr].call(this, element, settings);
      }
    };


    $.extend($.expr[':'], {
      "below-the-fold": function(a, i, m) {
        return $.viewport('belowthefold', a,  {threshold : 0});
      },
      "above-the-top": function(a, i, m) {
        return $.viewport('abovethetop', a,  {threshold : 0});
      },
      "left-of-screen": function(a, i, m) {
        return $.viewport('leftofscreen', a,  {threshold : 0});
      },
      "right-of-screen": function(a, i, m) {
        return $.viewport('rightofscreen', a,  {threshold : 0});
      },
      "in-viewport": function(a, i, m) {
        return $.viewport('inviewport', a,  {threshold : 0});
      }
    });

})(jQuery);
