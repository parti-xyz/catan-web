// 툴바 위치 고정
tinymce.PluginManager.add('stickytoolbar', function(editor, url) {
  var inited = false;
  editor.on('focus', function() {
    inited = true;
    setSticky();
  });

  $(window).on('scroll', _.debounce(setSticky, 100));

  function setSticky() {
    if(!inited) {
      return;
    }

    var container = editor.editorContainer;
    if(!$(container).is(':visible')) {
      return;
    }

    var $toolbars = $(container).find('.mce-toolbar-grp');
    var $statusbar = $(container).find('.mce-statusbar');

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
        $(document).trigger('parti-ios-virtaul-keyboard-open-for-tinymce');
      }
      $(container).css({
        paddingTop: $toolbars.outerHeight()
      });
      var top = (-1) + -1 * ($toolbars.outerHeight() + container.getBoundingClientRect().top) + viewportTopDelta;
      $toolbars.css({
        position: 'absolute',
        top: top,
        width: '100%'
      });
      $(container).addClass('mce-catan-tinymce-sticky');
      $toolbars.find('> .mce-container-body').addClass('mce-catan-container-body-sticky');
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
      $toolbars.find('> .mce-container-body').removeClass('mce-catan-container-body-sticky');
      $toolbars.find('> .js-mce-catan-sticky-toolbar').removeClass('mce-catan-toolbar-sticky');
    }
  }

  function isSticky(viewportTopDelta) {
    return isOverViewportTop(viewportTopDelta) && !isCompletedOverViewportTop(viewportTopDelta, 100);
  }

  function isOverViewportTop(viewportTopDelta) {
    var container = editor.editorContainer,
      editorTop = container.getBoundingClientRect().top;

    if (editorTop > viewportTopDelta) {
      return false;
    }

    return true;
  }

  function isCompletedOverViewportTop(viewportTopDelta, buffterHeight) {
    var container = editor.editorContainer,
      editorTop = container.getBoundingClientRect().top;

    var toolbarHeight = $(container).find('.mce-toolbar-grp').outerHeight();
    var footerHeight = $(container).find('.mce-statusbar').outerHeight();

    var hiddenHeight = -($(container).outerHeight() - toolbarHeight - footerHeight);

    if (editorTop < hiddenHeight + viewportTopDelta + buffterHeight) {
      return true;
    }

    return false;
  }
});

// h1 h2 h3 툴바
tinyMCE.PluginManager.add('stylebuttons', function(editor, url) {
  ['h1', 'h2', 'h3'].forEach(function(name){
    editor.addButton("style-" + name, {
      tooltip: "제목 " + name,
      text: name.toUpperCase(),
      onClick: function() { editor.execCommand('mceToggleFormat', false, name); },
      onPostRender: function() {
        var self = this, setup = function() {
          editor.formatter.formatChanged(name, function(state) {
            self.active(state);
          });
        };
        editor.formatter ? setup() : editor.on('init', setup);
      }
    })
  });
  $.each({br: '줄바꿈'}, function(name, display) {
    editor.addButton("style-" + name, {
      tooltip: display,
      text: display,
      onClick: function() {
        // editor.execCommand('mceInsertContent', false, "<br/>");
        uniqueId = "___cursor___" + Math.random().toString(36).substr(2, 16);
        editor.execCommand('mceInsertContent', false, "<br/><span id=" + uniqueId + "> </span> ");
        editor.selection.select(editor.dom.select('#' + uniqueId)[0]);
        editor.selection.collapse(0);
        editor.dom.remove(uniqueId);
      },
    });
  });
});

// 토글 툴바
tinymce.PluginManager.add('toggletoolbar', function(editor, url) {
  editor.on('init', function(){
    var $toggle_handler = $('<div class="js-tinymce-catan-toolbar-handle js-mce-catan-sticky-toolbar tinymce-catan-toolbar-handle"><i class="fa fa-paint-brush" style="font-family: \'FontAwesome\';"></div>');
    var container = editor.editorContainer;
    var $toolbars = $(container).find('.mce-toolbar-grp');
    $toolbars.append($toggle_handler);
    $toolbars.find('> .mce-container-body').hide().addClass('mce-container-body-toggletoolbar').addClass('js-mce-container-body-toggletoolbar');

    $toggle_handler.on('click', function(e) {
      $toolbars.find('.js-mce-container-body-toggletoolbar').slideToggle('fast');
    });
  });
});
