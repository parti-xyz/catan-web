var __parti_prepare_drawer = function($base) {
  // 내 채널 search
  $.parti_apply($base, '.js-drawer-filter-more', function(elm) {
    if ($('.js-drawer-filter-container').length > 0) {
      $(elm).appendTo('.js-drawer-filter-container').hide().removeClass('hidden');
    } else {
      $(elm).remove();
    }
  });

  $.parti_apply($base, '.js-drawer-filter', function(elm) {
    $(elm).addClear({
      onClear: function(){
        $(this).val('');
        $base.find(".js-drawer-filter").trigger('keyup');
      }
    });

    $(elm).on("keyup", _.debounce(function(e){
      if ($('.js-drawer-filter-container .js-drawer-filter-group').length <= 0) {
        return;
      }

      // Retrieve the input field text
      var filter = $(e.currentTarget).val();

      if ($.is_blank(filter)) {
        $('.js-drawer-filter-container').find('.js-drawer-filter-item').show();
        var $hidden = $('.js-drawer-filter-container').find('.js-drawer-filter-item-hidden');
        $hidden.removeClass('js-drawer-filter-item-hidden').show();
        $('.js-sidemenu-toggle').trigger('parti-sidemenu-toggle-reinit');
        $('.js-drawer-filter-more').fadeOut();
      } else {
        $('.js-drawer-filter-container').find('> :not(.js-drawer-filter-item)').addClass('js-drawer-filter-item-hidden');

        $('.js-drawer-filter-container .js-drawer-filter-group').each(function(){
          var has_shown_issue_in_group = false;

          $(this).find('.js-drawer-filter-ignored').addClass('js-drawer-filter-item-hidden');
          $(this).find('.js-drawer-filter-searchable-line').each(function() {
            // If the list item does not contain the text phrase fade it out
            if ($(this).text().search(new RegExp(filter, "i")) < 0) {
              $(this).addClass('js-drawer-filter-item-hidden');
            } else {
              // Show the list item if the phrase matches and increase the count by 1
              $(this).show().removeClass('js-drawer-filter-item-hidden');
              has_shown_issue_in_group = true;
            }
          });

          $(this).find('.js-drawer-filter-group-title').each(function() {
            // If the list item does not contain the text phrase fade it out
            if ($(this).text().search(new RegExp(filter, "i")) >= 0) {
              has_shown_issue_in_group = true;
            }
          });

          var $show_more_sidemenu_toggle = $(this).find('.js-sidemenu-toggle');
          if (has_shown_issue_in_group) {
            $(this).show().removeClass('js-drawer-filter-item-hidden');
            if ($(this).prev().hasClass('divider')) {
              $(this).prev().show().removeClass('js-drawer-filter-item-hidden');
            }
            $show_more_sidemenu_toggle.trigger('parti-sidemenu-toggle-show-temporary');
          } else {
            $(this).addClass('js-drawer-filter-item-hidden');
            $show_more_sidemenu_toggle.trigger('parti-sidemenu-toggle-hide-temporary');
          }
        });

        $('.js-drawer-filter-container').find('.js-drawer-filter-item-hidden').fadeOut();
        $('.js-drawer-filter-more').show();
      }
    }, 300));

    $(elm).on("parti-drawer-filter-temporary-ignore", function(e, temporary_container){
      e.preventDefault();
      $(temporary_container).find('.js-drawer-filter-item-hidden').show();
    });

    $(elm).on("parti-drawer-filter-temporary-reset", function(e, temporary_container){
      e.preventDefault();
      $(temporary_container).find('.js-drawer-filter-item-hidden').hide();
    });
  });

  // 내 메뉴의 그룹 토글
  (function() {
    $.parti_apply($base, '.js-sidemenu-toggle', function(elm) {
      var unfold_icon = 'fa-caret-down';
      var fold_icon = 'fa-caret-right';
      $(elm).on('click', function(e, force_mode) {

        var href = $(e.target).closest('a').attr('href')
        if (href && href != "#") {
          return true;
        }
        var _cookies_group_ids = Cookies.getJSON('opened_group_ids') || [];

        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues_container = $group.find('.js-sidemenu-toggle-issues-container');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        if($issues_container.hasClass('js-sidemenu-toggle-issues-fold-temporary')) {
          $('.js-drawer-filter').trigger('parti-drawer-filter-temporary-reset', $issues_container);
          $issues_container.addClass('js-sidemenu-toggle-issues-unfold-temporary');
          $issues_container.removeClass('js-sidemenu-toggle-issues-fold-temporary');
          $icon.removeClass(unfold_icon);
          $icon.addClass(fold_icon);
        } else if($issues_container.hasClass('js-sidemenu-toggle-issues-unfold-temporary')) {
          $('.js-drawer-filter').trigger('parti-drawer-filter-temporary-ignore', $issues_container);
          $issues_container.removeClass('js-sidemenu-toggle-issues-unfold-temporary');
          $issues_container.addClass('js-sidemenu-toggle-issues-fold-temporary');
          $icon.removeClass(fold_icon);
          $icon.addClass(unfold_icon);
        } else {
          var mode;
          if(force_mode) {
            mode = force_mode;
          } else {
            mode = ($issues_container.hasClass('js-sidemenu-toggle-issues-fold') ? 'unfold' : 'fold');
          }

          var group_id = 0;
          var group_id_str = $group.data('sidemenu-toggle-group-id');
          if(group_id_str) {
            group_id = parseInt(group_id_str);
          }

          if(mode == 'fold') {
            $issues_container.addClass('js-sidemenu-toggle-issues-fold');
            $issues_container.removeClass('js-sidemenu-toggle-issues-unfold');
            // $issues_container.hide();
            $issues_container.find('.js-sidemenu-highlight-menu-parti').hide();
            $issues_container.find('.js-sidemenu-highlight-menu-parti.js-sidemenu-highlight-current-item').show();
            $issues_container.find('.js-sidemenu-highlight-menu-parti.unread').show();
            $issues_container.find('.js-sidemenu-toggle-issues-container-underling').hide();

            $icon.removeClass(unfold_icon);
            $icon.addClass(fold_icon);

            _.pull(_cookies_group_ids, group_id);
          } else {
            $issues_container.removeClass('js-sidemenu-toggle-issues-fold');
            $issues_container.addClass('js-sidemenu-toggle-issues-unfold');
            // $issues_container.show();
            $issues_container.find('.js-sidemenu-highlight-menu-parti').show();
            $issues_container.find('.js-sidemenu-toggle-issues-container-underling').show();

            $icon.removeClass(fold_icon);
            $icon.addClass(unfold_icon);

            _cookies_group_ids.push(group_id);
          }

          _cookies_group_ids = _.uniq(_cookies_group_ids);
          if(_cookies_group_ids.length > 2000) {
            _cookies_group_ids.shift()
          }
          Cookies.set('opened_group_ids', _cookies_group_ids, { domain: '.' + __root_domain, expires: 7 });
        }
      });

      $(elm).on('parti-sidemenu-toggle-reinit', function(e) {
        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues_container = $group.find('.js-sidemenu-toggle-issues-container');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        if($issues_container.hasClass('js-sidemenu-toggle-issues-fold')) {
          // $issues_container.hide();
          $issues_container.find('.js-sidemenu-highlight-menu-parti').hide();
          $issues_container.find('.js-sidemenu-highlight-menu-parti.js-sidemenu-highlight-current-item').show();
          $issues_container.find('.js-sidemenu-highlight-menu-parti.unread').show();
          $issues_container.find('.js-sidemenu-toggle-issues-container-underling').hide()

          $icon.removeClass(unfold_icon);
          $icon.addClass(fold_icon);
        } else {
          // $issues_container.show();
          $issues_container.find('.js-sidemenu-highlight-menu-parti').show();
          $issues_container.find('.js-sidemenu-toggle-issues-container-underling').show();

          $icon.removeClass(fold_icon);
          $icon.addClass(unfold_icon);
        }
        $issues_container.removeClass('js-sidemenu-toggle-issues-fold-temporary');
        $issues_container.removeClass('js-sidemenu-toggle-issues-unfold-temporary');
      });

      $(elm).on('parti-sidemenu-toggle-show-temporary', function(e) {
        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues_container = $group.find('.js-sidemenu-toggle-issues-container');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        $issues_container.addClass('js-sidemenu-toggle-issues-unfold-temporary');
        $issues_container.removeClass('js-sidemenu-toggle-issues-fold-temporary');
        // $issues_container.show();
        $issues_container.find('.js-sidemenu-toggle-issues-container-underling').show();

        $icon.removeClass(unfold_icon);
        $icon.addClass(fold_icon);
      });

      $(elm).on('parti-sidemenu-toggle-hide-temporary', function(e) {
        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues_container = $group.find('.js-sidemenu-toggle-issues-container');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        $issues_container.addClass('js-sidemenu-toggle-issues-unfold-temporary');
        $issues_container.removeClass('js-sidemenu-toggle-issues-fold-temporary');
        // $issues_container.show();
        $issues_container.find('.js-sidemenu-toggle-issues-container-underling').hide();

        $icon.removeClass(unfold_icon);
        $icon.addClass(fold_icon);
      });
    });
  })();

  $.parti_apply($base, '.js-lazy-partal-load-drawer', function(elm) {
    $.ajax({
      url: $(elm).data('url'),
      type: 'get',
      crossDomain: false,
      data:{
        issue_id: __current_issue_id(),
        group_id: __current_group_id(),
      },
      xhrFields: {
        withCredentials: true
      }
    });
  });

  $.parti_apply($base, '.js-parti-drawer-search', function(elm) {
    $(elm).on('click', function(e) {
      var input_target = $(elm).data('input-target');
      var url = $(elm).data('url');
      var name = $(input_target).attr('name');
      var val = $(input_target).val();
      var params = {}
      params[name] = val;
      location.href = url + '?' + $.param(params);
    });
  });
}

$(function() {
  (function() {
    var $__sidebar_scroll_container = $('.js-sidebar-scroll-container').first();

    // 사이드바에서 현재 선택된 영역까지 얼마나 스크롤 해야하는지 선택
    var current_scroll_to = function($current_group_issue) {
      return $__sidebar_scroll_container.scrollTop();
      // var scroll_to = $__sidebar_scroll_container.scrollTop();
      // if($current_group_issue && $current_group_issue.length > 0) {
      //   $current_group_issue.prevAll().each(function(index, elm){
      //     var $unfold = $(elm).find('.js-sidemenu-toggle-issues-unfold');
      //     if($unfold.length > 0) {
      //       scroll_to -= $unfold.outerHeight();
      //     }
      //   });
      //   return scroll_to;
      // }

      // return 0;
    }

    var cal_fixed_top_height = function() {
      var result = 0;
      $.each($('.js-drawer-scroll-header-height'), function(index, each_elm) {
        result += $(each_elm).outerHeight()
      });
      return result;
    }

    var in_drawer_viewport = function($elm, fixed_top_height) {
      return !$.viewport('belowthefold', $elm,  {threshold: -1 * $elm.outerHeight()}) && !$.viewport('abovethetop', $elm,  {threshold: $elm.outerHeight() + fixed_top_height + $('#site-header').outerHeight()})
    }

    var init_scroll_sidebar = function(e, callback) {
      // 가급적 빨리 쿠키를 처리
      var scrollto_from_cookie = Cookies.get('sidebarScroll.' + location.host);
      if(scrollto_from_cookie) {
        Cookies.remove('sidebarScroll.' + location.host, { domain: __root_domain });
        sessionStorage.sidebarScroll = scrollto_from_cookie;
      }

      var $elm = $('.js-sidemenu-highlight-current-item').first();
      if($elm.length <= 0) {
        callback();
        return;
      }

      // 사이드바 활성화 여부 판단
      if($elm.offset().top === 0 && $elm.offset().left === 0) {
        var init_scroll_sidebar_on_slideopen = function(e) {
          init_scroll_sidebar(e, callback);
          $(document).off("parti-slide-open", init_scroll_sidebar_on_slideopen);
        }
        $(document).off("parti-slide-open", init_scroll_sidebar_on_slideopen);
        $(document).on("parti-slide-open", init_scroll_sidebar_on_slideopen);
        return;
      }

      var fixed_top_height = cal_fixed_top_height();

      if(scrollto_from_cookie) {
        $__sidebar_scroll_container.scrollTop(scrollto_from_cookie);
        if(in_drawer_viewport($elm, fixed_top_height)) {
          sessionStorage.sidebarScroll = $__sidebar_scroll_container.scrollTop();
          callback();
          return;
        }
      }

      if(sessionStorage.sidebarScroll) {
        $__sidebar_scroll_container.scrollTop(sessionStorage.sidebarScroll);
        if(in_drawer_viewport($elm, fixed_top_height)) {
          sessionStorage.sidebarScroll = $__sidebar_scroll_container.scrollTop();
          callback();
          return;
        }
      }

      var $current_group_issue = $elm.parents('.js-group-issues-line').first();
      $__sidebar_scroll_container.scrollTo($current_group_issue, {
        offset: {
          top: -1 * fixed_top_height
        }
      });
      if(in_drawer_viewport($elm, fixed_top_height)) {
        sessionStorage.sidebarScroll = $__sidebar_scroll_container.scrollTop();
        callback();
        return;
      }

      $__sidebar_scroll_container.scrollTo($elm, {
        offset: {
          top: (- 1 * (fixed_top_height + $elm.outerHeight()))
        }
      });
      sessionStorage.sidebarScroll = $__sidebar_scroll_container.scrollTop();
      callback();
    }

    // 사이드바에서 맨 상단으로 스크롤 업하기
    var drawer_init_scroll_top = function() {
      var $elm = $('.js-drawer-scroll-to-top');
      if($__sidebar_scroll_container.scrollTop() === 0) {
        return;
      } else {
        $elm.show();
      }

      $elm.on('click', function(e) {
        $__sidebar_scroll_container.scrollTop(0);
      });

      var scrollPosition = $__sidebar_scroll_container.scrollTop();
      var callback = _.throttle(function () {
        var is_bottom = false;
        var cursorPosition = $__sidebar_scroll_container.scrollTop();
        if (cursorPosition < scrollPosition) {
          $__sidebar_scroll_container.off('scroll', callback);
          $elm.hide('slide', { direction: "up" }, 300);
        }
        scrollPosition = cursorPosition;
      }, 300);
      $__sidebar_scroll_container.on('scroll', callback);
    };

    $(document).on('parti-drawer-init-scroll', function(e) {
      init_scroll_sidebar(e, drawer_init_scroll_top);
    });

    $(document).on('parti-drawer-click-group-issues-line', '[data-action="parti-issue-link"]', function(e) {
      var $elm = $(e.currentTarget);
      var $current_group_issue = $elm.parents('.js-group-issues-line').first();
      if(!$current_group_issue || $current_group_issue.length < 0) {
        return;
      }
      var group_id = $current_group_issue.data('sidemenu-toggle-group-id');
      var group_subdomain = $current_group_issue.data('sidemenu-toggle-group-subdomain');
      if(group_id && group_subdomain) {
        Cookies.set('sidebarScroll.' + group_subdomain + '.' + __root_domain, current_scroll_to($current_group_issue), { domain: __root_domain });
      }
    });
  })();

  // drawer
  // 1. mobile
  (function() {
    if($('body.js-menu-slideout').length <= 0 || $('#js-drawer').length <= 0 || $('#js-main-panel').length <= 0) {
      return;
    }

    var slideout = new Slideout({
      'panel': $('#js-main-panel')[0],
      'menu': $('#js-drawer')[0],
      'padding': 256,
      'tolerance': 70,
      'touch': false
    });

    $('.js-slideout-toggle').on('click', function(e) {
      e.preventDefault();
      slideout.toggle();
    });

    var $fixed = $('.js-fixed-header');
    function close(e) {
      e.preventDefault();
      slideout.close();
    }

    slideout.on('translate', function(translated) {
      if($fixed.length > 0) {
        $fixed.css('transform', 'translateX(' + translated + 'px)');
      }
      $(this.panel).addClass('main-panel-translate');
    });

    slideout.on('beforeopen', function () {
      $(document).trigger("parti-slide-beforeopen");
      if($fixed.length > 0) {
        $fixed.css('transition', 'transform 300ms ease');
        $fixed.css('transform', 'translateX(256px)');
        $fixed.addClass('site-header-open');
      } else {
        $(this.panel).addClass('main-panel-open');
      }
    });

    slideout.on('beforeclose', function () {
      if($fixed.length > 0) {
        $fixed.css('transition', 'transform 300ms ease');
        $fixed.css('transform', 'translateX(0px)');
        $fixed.off('click', close);
        $fixed.removeClass('site-header-open');
      } else {
        $(this.panel).removeClass('main-panel-open');
        $(this.panel).off('click', close);
      }
    });

    slideout.on('open', function () {
      $(document).trigger("parti-slide-open");
      $(document).trigger('parti-ios-virtaul-keyboard-close-for-tinymce');
      if($fixed.length > 0) {
        $fixed.css('transition', '');
        $fixed.on('click', close);
      } else {
        $(this.panel).on('click', close);
      }
      $(this.panel).removeClass('main-panel-translate');
    });

    slideout.on('close', function () {
      if($fixed.length > 0) {
        $fixed.css('transition', '');
      }
      $(this.panel).removeClass('main-panel-translate');
    });
  })();

  // 2. large screen
  (function() {
    if($('body.js-menu-slideout-lg').length <= 0 || $('#js-main-panel').length <= 0 || $('#js-drawer').length <= 0) {
      return;
    }

    $('.js-slideout-toggle').on('click', function(e) {
      e.preventDefault();
      if($('#js-drawer').is(':visible')) {
        $('#js-main-panel').removeClass('sidebar-open');
        Cookies.set('sidebar-open', false, { domain: '.' + __root_domain });
      } else {
        $('#js-main-panel').addClass('sidebar-open');
        Cookies.set('sidebar-open', true, { domain: '.' + __root_domain });
        $('#js-main-panel .js-sidebar-scroll-container').visibilityChanged({
          runOnLoad: true,
          frequency: 100,
          previousVisibility : false,
          callback: function(_, visible) {
            if(visible) {
              $(document).trigger("parti-slide-open");
            }
          }
        });
      }
      $('.js-bottom-banner').trigger('parti-resize-bottom-banner');
    });
  })();
});
