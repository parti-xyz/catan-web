//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require masonry.pkgd
//= require imagesloaded.pkgd.js
//= require jssocials
//= require unobtrusive_flash
//= require unobtrusive_flash_bootstrap
//= require jquery.timeago
//= require locales/jquery.timeago.ko
//= require jquery.remotipart
//= require autoresize
//= require jquery.validate
//= require additional-methods
//= require messages_ko
//= require kakao
//= require jquery.history
//= require jquery.waypoints
//= require sticky.js
//= require jquery.dotdotdot
//= require jquery.webui-popover
//= require bootstrap-add-clear
//= require diacritics
//= require bootstrap-select
//= require bootstrap-select/defaults-ko_KR.js
//= require jquery.viewport
//= require cocoon
//= require clipboard
//= require Sortable
//= require webp-check
//= require jquery.slick
//= require tinymce-jquery
//= require tinymce/plugins/hot_style
//= require tinymce/plugins/sticky_toolbar
//= require tinymce/plugins/sticky_toolbar_mobile
//= require Chart.bundle
//= require chartkick
//= require slideout
//= require js.cookie
//= require pulltorefresh
//= require photoswipe
//= require photoswipe-ui-default
//= require jquery.scrollTo
//= require loadash
//= require bootstrap-datepicker
//= require bootstrap-datepicker.kr.min
//= require jquery.timepicker
//= require datepair
//= require jquery.dirrty
//= require jquery.redirect
//= require smart-app-banner
//= require jquery.mosaic
//= require jquery-sortable
//= require jquery.ui.position.slide
//= require jquery-deepest
//= require visibilityChanged
//-- parti apps --
//= require drawer
//= require editor
//= require folder
//= require issue
//= require post
//= require search
//= require bookmark
//= require validation

// blank
$.is_blank = function (obj) {
  if (!obj || $.trim(obj) === "") return true;
  if (obj.length && obj.length > 0) return false;

  for (var prop in obj) if (obj[prop]) return false;

  if (obj) return false;
  return true;
}

// breakpoint
$('body').append($('<span id="js-xs-breakpoint" class="visible-xs-block"></span>'));
$('body').append($('<span id="js-sm-breakpoint" class="visible-sm-block"></span>'));
$('body').append($('<span id="js-md-breakpoint" class="visible-md-block"></span>'));
$.breakpoint_max = function() {
  if($('#js-xs-breakpoint.visible-xs-block').is(":visible")) {
    return 'xs';
  } else if($('#js-sm-breakpoint.visible-sm-block').is(":visible")) {
    return 'sm';
  } else if($('#js-md-breakpoint.visible-md-block').is(":visible")) {
    return 'md';
  } else {
    return 'lg';
  }
}

$.is_present = function(obj) {
  return ! $.is_blank(obj);
}

$.escape_regexp = function(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}

$.scroll_detection = function(options) {
    var settings = $.extend({
        scroll_up: function() {},
        scroll_down: function() {},
        scroll_bottom: null
    }, options);

    var scrollPosition = 0;
    $(window).on('scroll', _.debounce(function () {
      var is_bottom = false;
      if(settings.scroll_bottom) {
        is_bottom = ($(window).scrollTop() + $(window).height() == $(document).height());
      }

      var cursorPosition = $(this).scrollTop();
      if(is_bottom) {
        settings.scroll_bottom();
      } else if (cursorPosition > scrollPosition) {
        settings.scroll_down();
      } else if (cursorPosition < scrollPosition) {
        settings.scroll_up();
      }

      scrollPosition = cursorPosition;
    }, 300));
};

$.isValidSelector = function(selector) {
  if (typeof(selector) !== 'string') {
    return false;
  }
  try {
    var $element = $(selector);
  } catch(error) {
    return false;
  }
  return true;
}

// unobtrusive_flash
UnobtrusiveFlash.flashOptions['timeout'] = 5000;

// Kakao Key
Kakao.init('6cd2725534444560cb5fe8c77b020bd6');

var __root_domain = $('body').data('root-domain');

var __current_issue_id = function() {
  var $current_parti_source = $('.js-sidemenu-highlight-current-parti-source');
  var current_parti_id = '';
  if($current_parti_source.length > 0) {
    current_parti_id = $current_parti_source.data('sidemenu-highlight-current-parti-id');
  }

  return current_parti_id;
}

var __current_group_id = function() {
  var current_group_id = '';

  var $current_group_source = $('.js-sidemenu-highlight-current-group-source');
  if($current_group_source.length > 0) {
    current_group_id = $current_group_source.data('sidemenu-highlight-current-group-id');
  }

  if(current_group_id) {
    return current_group_id;
  }

  var $current_parti_source = $('.js-sidemenu-highlight-current-parti-source');
  if($current_parti_source.length > 0) {
    return $current_parti_source.data('sidemenu-highlight-current-group-id');
  }

  return current_group_id;
}

$.parti_apply = function($base, query, callback) {
  $.each($base.find(query).addBack(query), function(i, elm){
    callback(elm);
  });
}

var parti_prepare_masonry = function($base) {
  //masonry
  $.parti_apply($base, '.masonry-container', function(elm) {
    var options = {}
    options.itemSelector = $(elm).data('masonry-target');
    if (!options.itemSelector) {
      options.itemSelector = '.card';
    }
    var sizer = $(elm).data('masonry-grid-sizer');
    if (sizer) {
      options.columnWidth = sizer;
      options.percentPosition = true;
    }
    $(elm).masonry(options);
    $(elm).imagesLoaded().progress( function() {
      $(elm).masonry(options);
    });
  });
}

var parti_prepare = function($base, force) {
  if(!force && $base.data('parti-prepare-arel') == 'completed') {
    return;
  }

  __parti_prepare_form_validator($base);
  __parti_prepare_editor($base);
  __parti_prepare_search($base);
  __parti_prepare_post($base);
  __parti_prepare_drawer($base);
  __parti_prepare_folder($base);
  __parti_prepare_bookmark($base);

  //timeago
  $.parti_apply($base, 'time[data-time-ago]', function(elm) {
    $(elm).timeago();
  });
  //timeago 다음에 masonry를 적용
  parti_prepare_masonry($base);

  //clipboard
  $.parti_apply($base, '.js-clipboard', function(elm) {
    var clipboard = new Clipboard(elm);
    clipboard.on('success', function(e) {
      $(e.trigger).tooltip('show');
      // setTimeout(function() { $(e.trigger).tooltip('hide'); }, 1000);
      e.clearSelection();
    });
  });

  (function() {
    var setup_webui_popover = function(elm) {
      var options = {};
      var style = $(elm).data('style');
      if(style) {
        options['style'] = style;
      }

      var type = $(elm).data('type');
      if(type) {
        options['type'] = type;
      }

      var backdrop = $(elm).data('backdrop');
      if(backdrop) {
        options['backdrop'] = backdrop;
      }

      options['maxHeight'] = '50vh';

      var width = $(elm).data('width');
      if(width) {
        options['width'] = width;
      }

      $(elm).webuiPopover(options);
    }

    $.parti_apply($base, '[data-action="parti-share-popover"]', function(elm) {
      if(ufo.isApp()) {
        $(elm).on('click', function(e) {
          e.preventDefault();

          var $elm = $(e.currentTarget);
          var shareUrl = $elm.data('share-url');
          var shareText = $elm.data('share-text');
          ufo.post("share", { text: shareUrl + ' ' + shareText, url: shareUrl });
        });
      } else {
        setup_webui_popover(elm);
        (function() {
          var close_callback = function(e) {
            $(elm).webuiPopover('hide');
          }
          $(elm).on('shown.webui.popover', function(e) {
            $(document).on('ajax:before', close_callback);
          });
          $(elm).on('hide.webui.popover', function(e) {
            $(document).off('ajax:before', close_callback);
          })
        })();
      }
    });

    $.parti_apply($base, '[data-action="parti-popover"]', setup_webui_popover);
  })();

  //tab btn
  $.parti_apply($base, '.js-tab-btn', function(elm) {
    $(elm).on('shown.bs.tab', function (e) {
      $(e.target).closest('.js-tab-btn-container').hide();
      $($(e.target).attr('href')).find('form').trigger('parti-need-to-validate');
    });
  });

  $.parti_apply($base, '.js-tab-masonry', function(elm) {
    $(elm).on('shown.bs.tab', function (e) {
      parti_prepare_masonry($('body'));
    });
  });

  //hide
  $.parti_apply($base, '.js-basic-toggle', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();
      var $elm = $(e.currentTarget);

      var $hide_target = $($elm.data('hide-target'));
      $hide_target.hide();

      var $show_target = $($elm.data('show-target'));
      $show_target.show();

      var $inactive = $($elm.data('inactive-target'));
      $inactive.removeClass('active');
    });
  });

  //share
  jsSocials.shares["telegram"]["shareUrl"] = function() {
    return this.url;
  };
  jsSocials.shares["telegram"]["shareIn"] = "blank";

  $.parti_apply($base, '[data-action="parti-share"]', function(elm) {
    var $elm = $(elm);

    var url = $elm.data('share-url');
    var text = $elm.data('share-text');
    var share = $elm.data('share-provider');
    if ($.is_blank(share)) return;
    var image_url = $elm.data('share-image');
    if ($.is_blank(image_url)) image_url = location.protocol + "//" + location.hostname + "/images/parti_seo.png";
    var image_width = $elm.data('share-image-width');
    if ($.is_blank(image_width)) image_width = '300';
    var image_height = $elm.data('share-image-height');
    if ($.is_blank(image_height)) image_height = '155';

    switch(share) {
    case 'kakao-link':
      Kakao.Link.createTalkLinkButton({
        container: elm,
        label: text,
        image: {
          src: image_url,
          width: image_width,
          height: image_height
        },
        webLink: {
          text: '빠띠에서 보기',
          url: url
        }
      });
    break
    case 'kakao-story':
      $elm.on('click', function(e) {
        Kakao.Story.share({
          url: url,
          text: text
        });
      });
    break
    default:
      $elm.jsSocials({
        showCount: false,
        showLabel: false,
        shares: [share],
        text: text,
        url: url
      });
    }
  });

  // login overlay
  $.parti_apply($base, '[data-toggle="parti-login-overlay"]', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();
      var $elm = $(e.currentTarget);

      var after_login = $elm.attr('data-after-login');
      var $input = $('#login-overlay form input[name=after_login]');
      $input.val(after_login);

      var label_content = $elm.attr('data-label');
      var $label = $('#login-overlay .login-overlay__label');
      $label.html(label_content);

      $("#login-overlay").fadeToggle();
    });
  });
  $.parti_apply($base, '[data-dismiss="parti-login-overlay"]', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();
      $("#login-overlay").fadeOut(400, function() {
        var $input = $('#login-overlay form input[name=after_login]');
        $input.val('');
        var $label = $('#login-overlay .login-overlay__label');
        $label.html('');
      });
    });
  });

  // autoresize toggle
  $.parti_apply($base, '.js-autoresize', function(elm) {
    autosize($(elm));
  });

  // modal tooltip
  $.parti_apply($base, '[data-toggle="tooltip"]', function(elm) {
    $(elm).tooltip();
  });

  $.parti_apply($base, '[data-action="parti-show-more"]', function(elm) {
    $(elm).on('click',function (e){
      var $post = $($(this).data('more-wrapper'));
      $post.find('.original-body').show();
      $post.find('.truncated-body').hide();
    });
  });

  $.parti_apply($base, '.js-select-picker', function(elm) {
    $(elm).selectpicker('render');
  });

  // 링크를 누르면 이벤트를 트리거 하기
  $.parti_apply($base, 'a.js-trigger', function(elm) {
    $(elm).on('click', function(e) {
      var $elm = $(e.currentTarget);
      var href_value = $elm.attr('href');
      if(!href_value) {
        return;
      }
      var trigger_name = href_value.replace(/^#/, '');
      if(!trigger_name) {
        return;
      }
      var trigger_target = $elm.data('target');
      if(!trigger_target) {
        return;
      }
      e.preventDefault();

      var event = jQuery.Event(trigger_name);
      event.target = elm;
      $(trigger_target).trigger(event);
    });
  });

  $.parti_apply($base, '.js-datepair', function(elm) {
    $(elm).find('.js-datepair-time').timepicker({
      'showDuration': true,
      'timeFormat': 'a g:i',
      'lang': { am: '오전', pm: '오후', AM: '오전', PM: '오후', decimal: '.', mins: '분', hr: '시', hrs: '시간' }
    });
    $(elm).find('.js-datepair-date').datepicker({
      'format': 'yyyy년 m월 d일',
      'autoclose': true,
      'language': 'kr'
    });
    // initialize datepair
    var self_datepair = new Datepair(elm, {
      'dateClass': 'js-datepair-date',
      'timeClass': 'js-datepair-time',
    });

    var trigger_form_validation = function() {
      $(elm).find('.js-datepair-date:visible').first().trigger('parti-need-to-validate');
    }

    var set_extern_val = function(val) {
      $(elm).find('.js-datepair-date[data-rule-extern]').data('rule-extern-value', val);
      trigger_form_validation();
    }

    $(elm).find('.js-datepair-all-day-long').on('change', function(e) {
      var $time_input = $(elm).find('.js-datepair-time');
      if($(e.currentTarget).is(":checked")) {
        $time_input.hide();
      } else {
        $time_input.show();
      }
      trigger_form_validation();
    });

    $(elm).on('rangeSelected', function(){
      var all_day_long = $(elm).find('.js-datepair-all-day-long').is(":checked");
      var any_blank_times = ($(elm).find('.js-datepair-time').filter(function() { return $.is_blank($(this).val()); }).length > 0);
      if(any_blank_times && !all_day_long) {
        set_extern_val('false');
      } else {
        set_extern_val('valid');
      }
    }).on('rangeIncomplete', function(){
      var all_day_long = $(elm).find('.js-datepair-all-day-long').is(":checked");
      var any_blank_dates = ($(elm).find('.js-datepair-date').filter(function() { return $.is_blank($(this).val()); }).length > 0);
      if(!any_blank_dates && all_day_long) {
        set_extern_val('valid');
      } else {
        set_extern_val('false');
      }
    }).on('rangeError', function(){
      set_extern_val('false');
    });
  });

  $.parti_apply($base, '.js-hover-toggle', function(elm) {
    $(elm).hover(function(e) {
      $($(elm).data('hover-toggle')).show();
    }, function(e) {
      $($(elm).data('hover-toggle')).hide();
    });
  });

  $.parti_apply($base, '.js-lazy-partal-load', function(elm) {
    $.ajax({
      url: $(elm).data('url'),
      type: 'get',
      crossDomain: false,
      xhrFields: {
        withCredentials: true
      }
    });
  });

  $.parti_apply($base, '.js-image-mosaic', function(elm) {
    $(elm).Mosaic({
      maxRowHeight: 300,
      refitOnResize: true,
      refitOnResizeDelay: 500,
      innerGap: 6,
      maxRowHeightPolicy: 'tail',
      showTailWhenNotEnoughItemsForEvenOneRow: true
    });
  });

  // remote link in dropdown menu toggle the menu
  $.parti_apply($base, '.js-remote-toggle-dropdown-menu.dropdown-menu', function(elm) {
    $(elm).find('a[data-remote=true]').click(function () {
      $(this).closest('ul').prev('button').dropdown('toggle');
    });
  });

  $base.data('parti-prepare-arel', 'completed');
}

var parti_partial$ = function($partial, force) {
  parti_prepare($partial, force);

  return $partial;
}

var parti_ellipsis = function($partial) {
  $.parti_apply($partial, '[data-action="parti-ellipsis"]', function(elm) {
    $(elm).dotdotdot();
    $(elm).dotdotdot();
  });
  return $partial;
}

$(function(){
  parti_prepare($('body'));
  parti_ellipsis($('body'));

  $.each($('.slick-slider'), function(index, elm) {
    var lg = $(elm).data('slick-slider-lg') || 5;
    var md = $(elm).data('slick-slider-md') || 3;
    var xs = $(elm).data('slick-slider-xs') || 2;

    $(elm).on('init', function(event, slick, currentSlide, nextSlide){
      $(elm).trigger('parti-need-to-scroll-position');
    });

    $(elm).slick({
      dots: true,
      slidesToShow: lg,
      slidesToScroll: lg,
      nextArrow: '<span class="slick-custom-next"><span class="fa-stack"><i class="fa fa-circle fa-stack-1x fa-inverse"></i><i class="fa fa-chevron-circle-right fa-stack-1x"></i></span></span>',
      prevArrow: '<span class="slick-custom-prev"><span class="fa-stack"><i class="fa fa-circle fa-stack-1x fa-inverse"></i><i class="fa fa-chevron-circle-left fa-stack-1x"></i></span></span>',
      responsive: [
        {
          breakpoint: 960,
          settings: {
            slidesToShow: md,
            slidesToScroll: md
          }
        },
        {
          breakpoint: 480,
          settings: {
            slidesToShow: xs,
            slidesToScroll: xs
          }
        }
      ]
    });

    if( $(elm).data('auto-height') ) {
      var sliderAdaptiveHeight = function() {
        $(elm).find('.slick-slide').height('0');
        $(elm).find('.slick-slide.slick-active').height('auto');
        $(elm).find('.slick-list').height('auto');
        $(elm).slick('setOption', null, null, true);
      }

      $(elm).on('afterChange', function(event, slick, currentSlide, nextSlide){
        sliderAdaptiveHeight();
      });

      sliderAdaptiveHeight();
    }

    $(elm).css('visibility',  'visible');
  });

  // 채널 사이드바 hover 할때 가입 버튼 보이기
  $('.js-issue-line-hover').on('mouseenter', function(elm) {
    $(this).find('.js-join-sign').hide();
    $(this).find('.js-join-button').show();
  });
  $('.js-issue-line-hover').on('mouseleave', function(elm) {
    $(this).find('.js-join-button').hide();
    $(this).find('.js-join-sign').show();
  });

  // 알림드롭다운
  $('#js-notification a.js-notification-dropdown').on('click', function (e) {
    e.preventDefault();
    var $elm = $('#js-notification');
    $elm.toggleClass('open');
    if($elm.hasClass('open')) {
      $elm.find('li:not(.js-notification-dropdown-loading)').remove();
      $elm.find('li.js-notification-dropdown-loading').show();
      $.ajax({
        url: $elm.data('url'),
        type: "get"
      });
    }
  });
  $('body').on('click', function (e) {
    if (!$('#js-notification').is(e.target)
        && $('#js-notification').has(e.target).length === 0
        && $('.open').has(e.target).length === 0
    ) {
        $('#js-notification').removeClass('open');
    }
  });

  (function() {
    var visible = false;
    var unfold_icon = 'fa-caret-down';
    var fold_icon = 'fa-caret-right';
    $('.js-show-all-pinned-post').on('click', function(e) {
      $btn = $('.js-show-all-pinned-post').find('.js-show-all-pinned-post-btn');
      if(visible) {
        $('.js-posts-pinned-and-behold').hide();
        $btn.find('.js-show-all-pinned-post-btn-show').show();
        $btn.find('.js-show-all-pinned-post-btn-hide').hide();
      } else {
        $('.js-posts-pinned-and-behold').show();
        $btn.find('.js-show-all-pinned-post-btn-show').hide();
        $btn.find('.js-show-all-pinned-post-btn-hide').show();
      }
      visible = (!visible);
    });
  })();

  $('#site-header').on('show.bs.collapse','.collapse', function() {
      $('#site-header').find('.collapse.in').collapse('hide');
  });

  $(document).ajaxError(function (e, xhr, settings) {
    if(xhr.status == 500) {
      UnobtrusiveFlash.showFlashMessage('뭔가 잘못되었습니다. 곧 고치겠습니다.', {type: 'error'});
    } else if(xhr.status == 403) {
      UnobtrusiveFlash.showFlashMessage('권한이 없습니다.', {type: 'error'})
    } else if(xhr.status == 404) {
      UnobtrusiveFlash.showFlashMessage('어머나! 누가 지웠네요. 페이지를 새로 고쳐보세요.', {type: 'notice'});
    }
    $.each($('a[data-disable-with]'), function(index, elm) { $.rails.enableElement($(elm)) });
  });

  $('[data-action="parti-collapse"]').each(function(i, elm) {
    var parent = $(elm).data('parent');
    $(elm).on('click', function(e) {
      $(parent + ' .collapse').collapse('toggle');
      $(parent + ' [data-action="parti-collapse"]').toggleClass('collapsed');
    });
  });

  (function() {
    // 기본 콜백
    var default_callback = function(e) {
      var href = $(e.target).closest('a').attr('href')
      if (href && href != "#") {
        return true;
      }

      var $no_parti_link = $(e.target).closest('[data-no-parti-link="no"]')
      if ($no_parti_link.length) {
        return true;
      }

      var $no_parti_input = $(e.target).closest('input, textarea')
      if ($no_parti_input.length) {
        return true;
      }

      var $no_parti_link = $(e.target).closest('[data-toggle="parti-login-overlay"]')
      if ($no_parti_link.length) {
        return true;
      }

      e.preventDefault();
      var url = $(e.currentTarget).data("url");
      if(!url) {
        var $url_source = $($(e.currentTarget).data("url-source"));
        if($url_source.length > 0) {
          url = $url_source.data("url");
        }
      }

      if(!url) {
        return;
      }

      var type = $(e.currentTarget).data("type");
      if("remote" == type) {
        $.ajax({
          url: url,
          type: "get"
        });
      } else if($.is_present($(this).data('link-target'))) {
        window.open(url, $(this).data('link-target'));
      } else if (e.shiftKey || e.ctrlKey || e.metaKey) {
        window.open(url, '_blank');
      } else {
        window.location.href  = url;
      }
    }

    $(document).on('click', '[data-action="parti-issue-link"]', function(e) {
      $elm = $(e.currentTarget);
      $elm.trigger('parti-drawer-click-group-issues-line');
      default_callback(e);
    });

    $(document).on('click', '[data-action="parti-link"]', default_callback);
  })();

  $(document).on('click', 'a.js-download', function(e) {
    var url = $(e.currentTarget).attr("href");

    var target_url = $(e.target).closest('a').attr('href');
    if(url != target_url) {
      if (target_url && target_url != "#") {
        return true;
      }
    }

    var $no_parti_link = $(e.target).closest('[data-no-parti-link="no"]')
    if ($no_parti_link.length) {
      return true;
    }

    e.preventDefault();
    // 하위 호환을 위해 post_id를 남겨둡니다.
    var post_id = $(e.currentTarget).data("post-id");
    var file_source_id = $(e.currentTarget).data("file-source-id");
    var file_name = $(e.currentTarget).data("file-name");

    if(ufo.isApp()) {
      // 하위 호환을 위해 post_id를 남겨둡니다.
      ufo.post("download", { post: post_id, file: file_source_id, name: file_name });
    } else if($.is_present($(this).data('link-target'))) {
      window.open(url, $(this).data('link-target'));
    } else if (e.shiftKey || e.ctrlKey || e.metaKey) {
      window.open(url, '_blank');
    } else {
      window.location.href = url;
    }
  });

  // history back
  $('.js-btn-history-back-in-mobile-app').on('click', function(e) {
    e.preventDefault();
    if(ufo.isApp()) {
      ufo.goBack();
    }
  });

  // pull to refresh
  (function() {
    var ptr = PullToRefresh.init({
      mainElement: '#js-main-panel',
      distThreshold: 90,
      distMax: 110,
      distReload: 50,
      instructionsPullToRefresh: '다시 로딩하려면 잡아당겨 주세요',
      instructionsReleaseToRefresh: '다시 로딩하려면 놓아주세요',
      instructionsRefreshing: '다시 로딩 중',
      onRefresh: function(){ window.location.reload(); },
      shouldPullToRefresh: function(){
        return (!window.scrollY && !$('#js-drawer').is(':visible') && !$('body').hasClass('js-no-pull-to-refresh'));
      }
    });
  })();

  // photoswipe
  $('body').on('click', '.js-photoswipe .js-photoswipe-image', function(e) {
    var pswp_element = $('.pswp')[0];

    var $photoswipe = $(e.currentTarget).closest('.js-photoswipe');
    var items = $.makeArray($photoswipe.find('.js-photoswipe-image').map(function(index, image_element) {
      var item = {
        src: $(image_element).data('url'),
        w: $(image_element).data('width'),
        h: $(image_element).data('height')
      };
      var download_url = '';
      if($(image_element).data('original-url')) {
        item['downloadURL'] = $(image_element).data('original-url');
      }
      return item;
    }));

    var gallery = null;

    var $elm = $(e.currentTarget);

    // define options (if needed)
    var options = {
      // optionName: 'option value'
      // for example:
      index: $elm.data('index'),
      shareButtons: [
        {id: 'download', label: '원본 다운로드', url:'{{raw_image_url}}', download: true}
      ]
    };

    // Initializes and opens PhotoSwipe
    gallery = new PhotoSwipe(pswp_element, PhotoSwipeUI_Default, items, options);
    gallery.init();
  });

  // 모바일에서 상단 메뉴에 현 페이지 제목을 보여 줍니다
  $('.js-navbar-header').on('parti-navbar-header-fix', function(e) {
    var $el = $(e.currentTarget);
    if($el.hasClass('js-navbar-header-fixed')) {
      return;
    }
    $el.addClass('js-navbar-header-fixed');
    var $default = $el.find('.js-navbar-header-title-default');
    var $page = $el.find('.js-navbar-header-title-page');
    if(!$default.length || !$page.length) {
      return;
    }
    $default.stop().fadeOut(500, function() {
      if(!$page.is(':visible')) {
        $page.stop().fadeIn(500);
      }
    });
  });

  $('.js-navbar-header').on('parti-navbar-header-ease', function(e) {
    var $el = $(e.currentTarget);
    if(!$el.hasClass('js-navbar-header-fixed')) {
      return;
    }
    $el.removeClass('js-navbar-header-fixed');
  });

  $(window).on('scroll', _.debounce(function() {
    var $el = $('.js-navbar-header');
    if(!$el.length) {
      return;
    }
    if($el.hasClass('js-navbar-header-fixed')) {
      return;
    }

    var $default = $el.find('.js-navbar-header-title-default');
    var $page = $el.find('.js-navbar-header-title-page');
    if(!$default.length || !$page.length) {
      return;
    }
    if($default.is(':animated') || $page.is(':animated')) {
      return;
    }

    if($(this).scrollTop() >= 100) {
      if($default.is(':visible')) {
        $default.stop().fadeOut(500, function() {
          if(!$page.is(':visible')) {
            $page.stop().fadeIn(500);
          }
        });
      }
    } else {
      if($page.is(':visible')) {
        $page.stop().fadeOut(500, function() {
          if(!$default.is(':visible')) {
            $default.stop().fadeIn(500);
          }
        });
      }
    }
  }, 500));

  $('.js-scroll-top').on('click', function(e) {
    $.scrollTo(0, 200);
  });

  // 채널 하단에 가입 이나 소개 배너 붙박이
  $(".js-bottom-banner-wrapper").each(function(index, elm) {
    $(elm).parent().css('margin-bottom', $(elm).outerHeight());
  });
  $.scroll_detection({
    scroll_up: function() {
      $(".js-bottom-banner-wrapper").stop().slideDown();
    },
    scroll_down: function() {
      $(".js-bottom-banner-wrapper").stop().slideUp();
    },
    scroll_bottom: function() {
      if(!$(".js-bottom-banner-wrapper").is(':visible')) {
        $(".js-bottom-banner-wrapper").stop().slideDown();
      }
    }
  });

  // 내 홈 탭
  (function() {
    if($('.js-my-home-tab-sticky').length > 0){
      var sticky = new Waypoint.Sticky({
        element: $('.js-my-home-tab-sticky')[0],
        offset: function() {
          $offset = $('.js-my-home-tab-sticky-offset');
          if ($offset.length <= 0) {
            return 0;
          }

          return -1 * $offset.position().top;
        }
      })
    }
  })();

  (function() {
    if(window.matchMedia("screen and (max-width: 768px)").matches) {
      // 액션시트
      $('.js-dropdown-xs-actionsheet').on('show.bs.dropdown', function(e) {
        $(this).find('.dropdown-menu').first().stop(true, true).slideDown(400);
      });

      $('.js-dropdown-xs-actionsheet').on('hide.bs.dropdown', function(e) {
        $(this).find('.dropdown-menu').first().stop(true, true).slideUp(200);
      });
    }
  })();

  (function() {
    // 앵커 링크일때 해당 링크를 강조
    if($(location).attr('hash').length > 0) {
      if(!$.isValidSelector($(location).attr('hash'))) {
        return;
      }
      var $anchor = $($(location).attr('hash')).first();
      if($anchor.hasClass('js-stress-anchor')) {
        var $target = $($anchor.data('stress-target'));
        $target.addClass($anchor.data('stress-class'));
        setTimeout(function() { $target.removeClass($anchor.data('stress-class')); }, 3000);
      }
    }
  })();
});

// 공통 모달
$(function(){
  $(document).on('shown.bs.modal', '#js-modal-placeholder > .modal', function(e) {
    $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').addClass('collapse');
    $('#js-modal-placeholder .js-modal-placeholder-action-dialog').removeClass('collapse');
    parti_partial$($('#js-modal-placeholder .js-modal-placeholder-action-dialog'));
    $('body').addClass('shown-modal-placeholder');
  });

  $(document).on('hidden.bs.modal', '#js-modal-placeholder > .modal', function(e) {
    var $action_dialog = $('#js-modal-placeholder .js-modal-placeholder-action-dialog')
    $action_dialog.removeClass();
    $action_dialog.addClass('modal-dialog js-modal-placeholder-action-dialog collapse');
    $action_dialog.html('');
    $('#js-modal-placeholder .js-modal-placeholder-action-dialog').data('parti-prepare-arel', '')

    var $loading_dialog = $('#js-modal-placeholder .js-modal-placeholder-loading-dialog')
    $loading_dialog.removeClass();
    $loading_dialog.addClass('modal-dialog js-modal-placeholder-loading-dialog');
    $('body').removeClass('shown-modal-placeholder');
  });

  $(document).on('parti-close-modal-placeholder', function(e) {
    $('#js-modal-placeholder > .modal').modal("hide");
  });
});

var parti_show_modal$ = function($partial) {
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').removeClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').removeClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').addClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').addClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').html($partial);
  if($('#js-modal-placeholder > .modal').hasClass('in')) {
    parti_partial$($partial, true);
  } else {
    $('#js-modal-placeholder > .modal').modal("show");
  }
}

var parti_show_modal_sm$ = function($partial) {
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').removeClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').removeClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').addClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').addClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').html($partial);
  if($('#js-modal-placeholder > .modal').hasClass('in')) {
    parti_partial$($partial, true);
  } else {
    $('#js-modal-placeholder > .modal').modal("show");
  }
}