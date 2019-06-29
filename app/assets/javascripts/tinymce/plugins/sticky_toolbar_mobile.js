tinymce.PluginManager.add('stickytoolbar-mobile', function(editor, url) {
  var inited = false;
  editor.on('focus', function() {
    inited = true;
    setSticky();
  });

  $(window).on('scroll', _.debounce(setSticky, 10));

  function setSticky() {
    if(!inited) {
      return;
    }

    var container = editor.editorContainer;
    if(!$(container).is(':visible')) {
      return;
    }

    $(container).find('.tox-editor-container').css('position', 'relative');
    var $toolbars = $(container).find('.tox-toolbar');
    var $statusbar = $(container).find('.tox-statusbar');

    var viewportTopDelta = 0;

    if(!$('body').hasClass('ios')) {
      var $offsets = $('.js-stickytoolbar-offset').filter(function () {
        return $(this).css('position') == 'fixed';
      });
      $offsets.each(function() {
        var absoluteTop = parseFloat($(this).outerHeight() + $(this).position().top);
        viewportTopDelta = absoluteTop > viewportTopDelta ? absoluteTop : viewportTopDelta;
      });
    }
    if (isSticky(viewportTopDelta)) {
      if($('body').hasClass('ios')) {
        $toolbars.css('visibility', 'hidden');
        var scrollStopTimeoutMS = 500;
        if ($(container).data('scrolltimeout')) {
          clearTimeout($(container).data('scrolltimeout'));
        }
        $(container).data('scrolltimeout', setTimeout(function() {
          $toolbars.css('visibility', 'visible');
        }, scrollStopTimeoutMS));
      }

      if($('body').hasClass('ios')) {
        $(document).trigger('parti-ios-virtaul-keyboard-open-for-tinymce');
      }
      $(container).css({
        paddingTop: $toolbars.outerHeight()
      });
      if($('body').hasClass('ios')) {
        var top = (-1) + -1 * ($toolbars.outerHeight() + container.getBoundingClientRect().top) + viewportTopDelta;
        $toolbars.css({
          position: 'absolute',
          top: top,
          width: '100%'
        });
      } else {
        var top = (-1) + (-1 * $toolbars.outerHeight()) + viewportTopDelta;
        var width = $(container).outerWidth() - 1;
        $toolbars.css({
          position: 'fixed',
          top: viewportTopDelta,
          width: width
        });
      }
      $(container).addClass('mce-catan-tinymce-sticky');
      $toolbars.addClass('mce-catan-container-body-sticky');
      $toolbars.find('> .js-mce-catan-sticky-toolbar').addClass('mce-catan-toolbar-sticky');
    } else {
      $(container).css({
        paddingTop: 0
      });
      $toolbars.css({
        position: 'relative',
        top: 0,
        width: '100%'
      });
      $(container).removeClass('mce-catan-tinymce-sticky');
      $toolbars.removeClass('mce-catan-container-body-sticky');
      $toolbars.find('> .js-mce-catan-sticky-toolbar').removeClass('mce-catan-toolbar-sticky');
    }
  }

  function isSticky(viewportTopDelta) {
    return isReading(viewportTopDelta) && !isAlreadRead(viewportTopDelta, 100);
  }

  function isReading(viewportTopDelta) {
    var container = editor.editorContainer,
      editorTop = container.getBoundingClientRect().top;
    var toolbarHeight = $(container).find('.mce-toolbar-grp').outerHeight();
    var footerHeight = $(container).find('.mce-statusbar').outerHeight();

    if ((editorTop + toolbarHeight + footerHeight) > viewportTopDelta) {
      return false;
    }

    return true;
  }

  function isAlreadRead(viewportTopDelta, buffterHeight) {
    var container = editor.editorContainer,
      editorTop = container.getBoundingClientRect().top;

    var toolbarHeight = $(container).find('.tox-toolbar').outerHeight();
    var footerHeight = $(container).find('.tox-statusbar').outerHeight();

    var hiddenHeight = -($(container).outerHeight() - toolbarHeight - footerHeight);

    if (editorTop < hiddenHeight + viewportTopDelta + buffterHeight) {
       return true;
     }

     return false;
   }
});
