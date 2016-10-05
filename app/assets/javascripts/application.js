//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require bootstrap-typeahead
//= require masonry.pkgd
//= require jquery.oembed
//= require jssocials
//= require owl.carousel
//= require unobtrusive_flash
//= require unobtrusive_flash_bootstrap
//= require bootstrap-tabdrop
//= require rails-timeago
//= require locales/jquery.timeago.ko
//= require autoresize
//= require jquery.validate
//= require messages_ko
//= require kakao
//= require jquery.pjax
//= require jquery.history
//= require jquery.waypoints
//= require jquery.typewatch
//= require jquery.dotdotdot
//= require jquery.webui-popover
//= require redactor2_rails/config
//= require redactor
//= require redactor2_rails/langs/ko
//= require bootstrap-add-clear
//= require diacritics
//= require bootstrap-dropdown-filter
//= require simplemde
//= require jquery.charactercounter
//= require bootstrap-select
//= require bootstrap-select/defaults-ko_KR.js
//= require jquery.viewport

// blank
$.is_blank = function (obj) {
  if (!obj || $.trim(obj) === "") return true;
  if (obj.length && obj.length > 0) return false;

  for (var prop in obj) if (obj[prop]) return false;

  if (obj) return false;
  return true;
}

$.is_present = function(obj) {
  return ! $.is_blank(obj);
}

$.parseDiv$ = function(str) {
  return $($.parseHTML('<div>' + $.trim(str) + '</div>'));
}

$.parse$ = function(str) {
  return $($.parseHTML($.trim(str)));
}

$.prevent_click_exclude_parti = function(e) {
  e.preventDefault();
  $(e.currentTarget).trigger('parti-click');
}
// unobtrusive_flash
UnobtrusiveFlash.flashOptions['timeout'] = 30000;

// Kakao Key
Kakao.init('6cd2725534444560cb5fe8c77b020bd6');

// form validation by extern
$.validator.addMethod("extern", function(value, element) {
  return this.optional(element) || $(element).data('rule-extern-value');
}, "");

$.parti_apply = function($base, query, callback) {
  $.each($base.find(query), function(i, elm){
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
  });
}

var parti_prepare = function($base) {
  if($base.data('parti-prepare-arel') == 'completed') {
    return;
  }

  parti_prepare_masonry($base);

  $base.find('[data-action="parti-popover"]').webuiPopover();


  $.parti_apply($base, 'form #note_body', function(elm) {
    var limit_count = $(elm).data('rule-maxlength');
    if($.is_blank(limit_count)) {
      limit_count = 100;
    }
    $(elm).characterCounter({
      limit: limit_count,
      counterFormat: '%1자를 더 쓸 수 있습니다.',
    });
  });

  // typeahead

  $.parti_apply($base, '[data-provider="parti-issue-typeahead"]', function(elm) {
    var $elm = $(elm);
    var url = $elm.data('typeahead-url');
    var displayField = $elm.data('typeahead-display-field');

    if (!url) return;

    $elm.bind('keydown', function(e) {
        if (e.keyCode == 13) {
          e.preventDefault();
        }
    });
    var clear_error = function() {
      $elm.closest('.form-group').removeClass('has-error')
          .find('.help-block.typeahead-warning').empty().hide();
      // form validation
      $elm.data('rule-extern-value', true);
      $elm.trigger('parti-need-to-validate');
    }
    $elm.typeahead({
      onSelect: function(item) {
        $elm.data('title', item.text );
        clear_error();
      },
      ajax: {
        url: url,
        timeout: 500,
        displayField: displayField || 'name',
        triggerLength: 1,
        method: "get",
        preProcess: function (data) {
          return data;
        }
      }
    }).on('keydown', function() {
      $elm.data('rule-extern-value', false);
      $elm.trigger('parti-need-to-validate');
    }).on('blur', function(e){
      if($(e.relatedTarget).data('disabled-typeahead-validation')) {
        return true;
      }
      if($(this).data('typeahead').shown) {
        return;
      }
      if ( $.is_blank($(this).val()) ) {
        clear_error();
        $elm.data('rule-extern-value', false);
        return;
      }
      if ( $(this).val() === $elm.data('title') ) {
        clear_error();
      } else {
        $.ajax({
          url: "/parties/exist.json",
          type: "get",
          data:{ title: $elm.val() },
          success: function(data) {
            if($.parseJSON(data)) {
              clear_error();
            } else {
              $elm.closest('.form-group').addClass('has-error')
              var $help_block = $elm.closest('.form-group').find('.help-block.typeahead-warning')

              $help_block.show().html('<span class="text-danger">자동 완성된 빠띠나 추천하는 빠디를 선택해야 합니다.</span>');
              // form validation
              $elm.data('rule-extern-value', false);
              $elm.trigger('parti-need-to-validate');
            }
          },
          error: function(xhr) {
            //ignore server error
            clear_error();
          }
        });
      }
    });
  });

  //switch
  $.parti_apply($base, '[data-action="parti-switch"]', function(elm) {
    var $elm = $(elm);
    $elm.on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);

      var $target = $($elm.data('switch-target'));
      var $target_base = $($elm.data('switch-target-base'));
      $target_base.hide();
      $target.show();

      var $source_base = $($elm.data('switch-source-base'));
      $source_base.removeClass("active");
      $elm.addClass("active");

      var focus_id = $elm.data('focus');
      $focus = $(focus_id);
      $focus.focus();
    });
  });

  // show
  $.parti_apply($base, '[data-action="parti-show"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);
      var $target = $($elm.data('show-target'));
      $target.show();
      var focus_id = $elm.data('focus');
      $focus = $(focus_id);
      $focus.focus();
      if($elm.data('self-hide')) {
        $elm.hide();
      }
    });
  });

  //hide
  $.parti_apply($base, '[data-action="parti-hide"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);
      var $target = $($elm.data('hide-target'));
      $target.hide();

      var $inactive = $($elm.data('inactive-target'));
      $inactive.removeClass('active');
    });
  });

  // focus
  $.parti_apply($base, '[data-action="parti-focus"]', function(elm) {
    $(elm).on('click', function(e) {
      var $elm = $(e.currentTarget);
      var $target = $($elm.data('focus-target'));
      setTimeout(function(){
        $target.focus();
      },10);
    });
  });

  //share
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
        showCount: true,
        showLabel: false,
        shares: [share],
        text: text,
        url: url
      });
    }
  });

  // carousel
  $.parti_apply($base, '[data-action="parti-carousel"]', function(elm) {
    var $elm = $(elm);
    var margin = $elm.data('carousel-margin');
    if(!margin) {
      margin = 0;
    }
    var items = $elm.data('carousel-items');
    if(!items) {
      items = 3;
    }
    var items_mobile = $elm.data('carousel-items-mobile');
    if(!items_mobile) {
      items_mobile = 2;
    }
    var slide_by = $elm.data('carousel-slide-by');
    if(!slide_by) {
      slide_by = 'page';
    }
    var dots = $elm.data('carousel-dots');
    if(!dots) {
      dots = false;
    }
    var dots_each = $elm.data('carousel-dots-each');
    if(!dots_each) {
      dots_each = false;
    }
    var dots_each = $elm.data('carousel-dots-each');
    if(!dots_each) {
      dots_each = false;
    }
    var loop_check = $elm.data('loop');
    if(loop_check == 'no') {
      loop = false;
    }else {
      loop = $elm.children().length > 1;
    }

    $elm.owlCarousel({
      loop: loop,
      nav: $elm.children().length > 1,
      slideBy: slide_by,
      margin: margin,
      dots: true,
      dotsEach: dots_each,
      navText: false,
      merge: true,
      responsive:{
        0:{
          items: items_mobile,
          mergeFit: true
        },
        768:{
          items: items,
          mergeFit: false
        }
      }
    });
    var next = $elm.data('carousel-next');
    var prev = $elm.data('carousel-prev');
    $(next).click(function(){
      $elm.data('owl.carousel').next();
    });
    $(prev).click(function(){
      $elm.data('owl.carousel').prev();
    });

    if($elm.children().length > 1) {
      if($elm.data('carousel-random')) {
        $elm.trigger('to.owl.carousel', 1 + Math.floor(Math.random() * $elm.children().length));
      }
    }
  });

  // login overlay
  $.parti_apply($base, '[data-toggle="parti-login-overlay"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
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
      $.prevent_click_exclude_parti(e);
      $("#login-overlay").fadeOut(400, function() {
        var $input = $('#login-overlay form input[name=after_login]');
        $input.val('');
        var $label = $('#login-overlay .login-overlay__label');
        $label.html('');
      });
    });
  });

  // form submit by clicking link
  $.parti_apply($base, '[data-action="parti-form-submit"]', function(elm) {
    $(elm).on('click', function(e) {
      $('[data-action="parti-form-submit"]').attr('disabled', true);
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);
      var $form = $($elm.data('form-target'));
      var url = $elm.data('form-url');
      $form.attr('action', url);
      $form.submit();
    });
  });

  // form set value
  $.parti_apply($base, '[data-action="parti-form-set-vaule"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);
      var $control = $($elm.data('form-control'));
      var value = $elm.data('form-vaule');
      $control.val(value);
      $control.trigger("blur");
    });
  });

  // autoresize toggle
  $.parti_apply($base, '[data-ride="parti-autoresize"]', function(elm) {
    autosize($(elm));
  });

  // form validator
  $.parti_apply($base, '[data-action="parti-form-validation"]', function(elm) {
    var $elm = $(elm);
    var $form = $(elm);
    var $submit = $($elm.data("submit-form-control"));
    $submit.prop('disabled', true);

    $form.validate({
      ignore: ':hidden:not(.redactor)',
      errorPlacement: function(error, element) {
        return true;
      }
    });

    $elm.find(':input').on('input', function(e) {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });

    $elm.find(':input').on('change', function(e) {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });

    $elm.find('select').on('change', function(e) {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });

    $elm.find(':input').on('parti-need-to-validate', function(e) {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });

    $elm.find('.redactor').on('change.callback.redactor', function() {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });
  });

  // mention
  $.parti_apply($base, '[data-action="parti-mention"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $target = $(e.currentTarget);
      var $control = $($target.data('mention-form-control'));
      var nickname = $target.data('mention-nickname');
      var value = $control.val();
      if(nickname) {
        $control.val('@' + nickname + ' ' + value);
      }
      $control.focus();
    });
  });

  // cancel form on blur
  $.parti_apply($base, '[data-action="parti-cancel-form-on-blur"]', function(elm) {
    var $elm = $(elm);

    var close_form = function(e) {
      if($elm.attr('id') != $(e.target).parents('form').attr('id')) {
        var $control = $($elm.data('cancel-form-control'));
        $(document).off('click', close_form);
        $(document).off('parti-click', close_form);
        $(document ).unbind('ajaxStart', close_form);
        $control.click();
      }
    }

    $(document).on('click', close_form);
    $(document).on('parti-click', close_form);
  });

  //permalink post
  $.parti_apply($base, '#post-modal', function(elm) {
    if(!$(elm).hasClass('post-modal-permlink')) {
      return;
    }
    var list_url = $(elm).data("list-url");
    var list_title = $(elm).data("list-title");
    $(elm).on('hidden.bs.modal', function (e) {
      History.pushState(null, list_title, list_url);
    });

    var post_modal_url = History.getState().url;
    var post_modal_index = History.getCurrentIndex;
    window.onstatechange = function(){
      var current_url = History.getState().url;
      var current_index = History.getCurrentIndex;
      if(post_modal_url == current_url && post_modal_index == current_index) {
        $(elm).modal('show');
      } else {
        $(elm).modal('hide');
      }
    };
    $(elm).modal('show');
  });

  //new comments count
  $.parti_apply($base, '[data-action="parti-polling"]', function(elm) {
    var $elm = $(elm);
    var polling_url = $(elm).data("polling-url");
    var polling_interval = $(elm).data("polling-interval");

    var update_new_comments = function() {
      $.getScript(polling_url);
      setTimeout(update_new_comments, polling_interval);
    }
    setTimeout(update_new_comments, polling_interval);
  });

  // modal tooltip
  $.parti_apply($base, '[data-toggle="tooltip"]', function(elm) {
    $(elm).tooltip();
  });

  // hover
  $.parti_apply($base, '[data-action="parti-hover"]', function(elm) {
    var $elm = $(elm);
    var hover_on = $(elm).data("hover-on");
    var hover_off = $(elm).data("hover-off");
    $elm.html(hover_off);
    $elm.on('mouseenter', function (e) {
      var $target = $(e.currentTarget);
      $target.html(hover_on);
    });
    $elm.on('mouseleave', function (e) {
      var $target = $(e.currentTarget);
      $target.html(hover_off);
    });
  });

  // unified editor
  $.parti_apply($base, '[data-action="parti-show-after-focused"]', function(elm) {
    var $elm = $(elm);
    var focus_target = $(elm).data("focus-target");

    $(focus_target).on('focus', function(){
      $elm.show();
    });
  });

  $.parti_apply($base, '[data-action="parti-click"]', function(elm) {
    var target = $(elm).data('target');
    $(elm).on('click', function(e) {
      $(target).click();
    });
  });

  $base.data('parti-prepare-arel', 'completed');
}

//parti-post-modal
var parti_prepare_post_modal = function($base) {
  if($base.data('parti-prepare-post-modal-arel') == 'completed') {
    return;
  }
  var target = '#post-modal'
  var $target = $(target);
  var container = target + ' .post-modal__partial-content';

  var nickname = '';
  var mention_form_control = '';
  var is_mention = false;

  $target.data('parti-pjax-back-trigger', 'off');
  $target.on('pjax:success', function(e, data, status, xhr, options) {
    parti_prepare($(container).children());
    $target.data('parti-pjax-back-trigger', 'on');

    var nickname = $target.data('mention-nickname');
    var mention_form_control = $target.data('mention-form-control');
    var control = $target.find(mention_form_control);

    is_mention = $.is_present(mention_form_control) && $.is_present(nickname);
    if (is_mention) {
      var value = $(control).val();
      var at_nickname = '@' + nickname;
      if ($.is_blank(value) || value.indexOf(at_nickname) == -1) {
        $(control).val(at_nickname + ' ' + value);
      }
    }
    if ($.is_present(mention_form_control)) {
      $target.on('shown.bs.modal', function (e) {
        $(control).focus();
      });
    }
    $target.modal('show');
  });
  $target.on('hidden.bs.modal', function (e) {
    if($target.data('parti-pjax-back-trigger') == 'on') {
      $target.data('parti-pjax-back-trigger', 'off')
      window.history.back();
    }
    $target.data('mention-nickname', '');
    $target.data('mention-form-control', '');
  });
  $target.on('pjax:popstate', function(e) {
    $target.data('parti-pjax-back-trigger', 'off');
    if(e.direction == "back" && $target.is(":visible")) {
      $target.modal('hide');
    }
  });

  $.each($base.find('[data-toggle="parti-post-modal"]'), function(i, elm) {
    var $elm = $(elm);

    var url = $elm.data("url");
    var nickname = $elm.data('mention-nickname');
    var mention_form_control = $elm.data('mention-form-control');
    $elm.on('click', function(e) {
      var href = $(e.target).closest('a').attr('href')
      if (href && href != "#") {
        return true;
      }
      $target.data('mention-nickname', nickname);
      $target.data('mention-form-control', mention_form_control);
      $.pjax({url: url, container: container, scrollTo: false, timeout: 5000});
      return false;
    });
  });

  $.each($base.find('[data-action="parti-filter-parties"]'), function(i, elm) {
    var $elm = $(elm);
    $elm.on('click', function(e) {
      var search_input = $(this).data('search-input');
      var sort = $(this).data('search-sort');
      var category = $(this).data('search-category');
      var $elm = $(this);

      $('.parties-all-loading').show();
      $('.parties-all-list').hide();
      $.ajax({
        url: '/parties/search.js',
        type: "get",
        data:{
          keyword: $(search_input).val(),
          sort: sort,
          category: category
        },
        complete: function(xhr) {
          $('.parties-all-loading').hide();
          $('.parties-all-list').show().trigger('parti-home-searched');
        },
      });
      return false;
    });
  });

  $base.data('parti-prepare-post-modal-arel', 'completed');
};

var parti_partial = function(partial) {
  var $partial = $.parseDiv$(partial);
  parti_prepare_post_modal($partial);
  parti_prepare($partial);

  return $partial;
}

var parti_origin_partial = function(partial) {
  var $partial = $.parse$(partial);
  parti_prepare_post_modal($partial);
  parti_prepare($partial);

  return $partial;
}

var parti_ellipsis = function($partial) {
  $.parti_apply($partial, '[data-action="parti-ellipsis"]', function(elm) {
    $(elm).dotdotdot();
    if($(elm).html() != $(elm).attr('title')) {
      $(elm).tooltip();
    }
  });
  return $partial;
}


$(function(){
  parti_prepare($('body'));
  parti_prepare_post_modal($('body'));
  parti_ellipsis($('body'));

  $('#new-theme-site-header').on('show.bs.collapse','.collapse', function() {
      $('#new-theme-site-header').find('.collapse.in').collapse('hide');
  });

  $('[data-action="parti-home-editor"] a[data-toggle="tab"]').on('show.bs.tab', function (e) {
    $(e.target).closest('[data-action="parti-home-editor"]').addClass('active');
  })

  $('.parti-editor-selectpicker').selectpicker('render');
  $('.parti-editor-selectpicker').on('changed.bs.select', function(e) {
    var select_value = $(this).val();
    $('form.form-widget input[name*="[issue_id]"]').val(select_value);
  });


  $(document).ajaxError(function (e, xhr, settings) {
    if(xhr.status == 500) {
      UnobtrusiveFlash.showFlashMessage('뭔가 잘못되었습니다. 곧 고치겠습니다.', {type: 'error'})
    } else if(xhr.status == 404) {
      UnobtrusiveFlash.showFlashMessage('어머나! 누가 지웠네요. 페이지를 새로 고쳐보세요.', {type: 'notice'})
    }
  });

  $('[data-action="parti-collapse"]').each(function(i, elm) {
    var parent = $(elm).data('parent');
    $(elm).on('click', function(e) {
      $(parent + ' .collapse').collapse('toggle');
      $(parent + ' [data-action="parti-collapse"]').toggleClass('collapsed');
    });
  });

  $('[data-action="parti-link"]').on('click', function(e) {
    e.preventDefault();
    var url = $(e.currentTarget).data("url");
    window.location.href  = url;
  });

  (function() {
    var load_page = function(waypoint) {
      waypoint.disable();

      var $container = $($(waypoint.element).data('target'));
      if($container.data('is-last')) {
        return;
      }

      $('.page_waypoint__loading').show();

      $.ajax({
        url: $(waypoint.element).data('url'),
        type: "get",
        data:{ last_id: $container.data('last-id') },
        context: waypoint,
        complete: function(xhr) {
          $('.page_waypoint__loading').hide();
          Waypoint.enableAll();
          Waypoint.refreshAll();
          waypoint = this
          setTimeout(function(){
            if($.inviewport(waypoint.element, {threshold : 100})) {
              load_page(waypoint);
            }
          },100);
        },
      });
    }
    $('.page_waypoint').waypoint({
      handler: function(direction) {
        load_page(this);
      },
      offset: 'bottom-in-view'
    });
  })();

  $('[data-action="parti-search-parties"]').each(function(i, elm) {
    var sort = $(elm).data('search-sort');
    var options = {
      callback: function (value) {
        $('.parties-all-loading').show();
        $('.parties-all-list').hide();
        $.ajax({
          url: '/parties/search.js',
          type: "get",
          data:{
            keyword: value,
            sort: $(sort).val()
          },
          complete: function(xhr) {
            $('.parties-all-loading').hide();
            $('.parties-all-list').show().trigger('parti-home-searched');
          },
        });
      },
      wait: 500,
      highlight: true,
      allowSubmit: false,
      captureLength: 2
    }
    $(elm).addClear();
    $(elm).typeWatch( options );
  });

  // Initialize Redactor
  $('.redactor').redactor({
    buttons: ['format', 'bold', 'italic', 'deleted', 'lists', 'link', 'horizontalrule'],
    plugins: ['wiki_save'],
    callbacks: {
      imageUploadError: function(json, xhr) {
        UnobtrusiveFlash.showFlashMessage(json.error.data[0], {type: 'notice'})
      }
    }
  });
  $('.redactor .redactor-editor').prop('contenteditable', true);

  $('[data-action="parti-home-slide"] a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var hash = $(e.target).attr('href');
    var $containers = $($(e.target).data('slide-target'));
    var $all_tab_panes = $($containers.find('.tab-pane'))
    var $target_tab_panes = $($containers.find('.tab-pane' + hash))
    $all_tab_panes.removeClass('active');
    $target_tab_panes.addClass('active');
  })

  // SimpleMDE
  if ( $( ".simplemde" ).length ){
    var $elm = $($(".simplemde")[0])
    var simplemde = new SimpleMDE({
      autosave: {
        enabled: false,
      },
      element: $(".simplemde")[0],
      spellChecker: false,
      status: false,
      toolbar: [
        {
          name: "bold",
          action: SimpleMDE.toggleBold,
          className: "fa fa-bold",
          title: "굵게",
        },
        {
          name: "italic",
          action: SimpleMDE.toggleItalic,
          className: "fa fa-italic",
          title: "기울임",
        },
        {
          name: "strikethrough",
          action: SimpleMDE.toggleStrikethrough,
          className: "fa fa-strikethrough",
          title: "취소선"
        },
        {
          name: "heading",
          action: SimpleMDE.toggleHeadingSmaller,
          className: "fa fa-header",
          title: "제목",
        },  '|',
        {
          name: "quote",
          action: SimpleMDE.toggleBlockquote,
          className: "fa fa-quote-left",
          title: "인용",
        },
        {
          name: "unordered-list",
          action: SimpleMDE.toggleUnorderedList,
          className: "fa fa-list-ul",
          title: "글머리 기호 넣기",
        },
        {
          name: "ordered-list",
          action: SimpleMDE.toggleOrderedList,
          className: "fa fa-list-ol",
          title: "순번 매기기",
        },  '|',
        {
          name: "link",
          action: SimpleMDE.drawLink,
          className: "fa fa-link",
          title: "링크 연결",
        },
        {
          name: "image",
          action: SimpleMDE.drawImage,
          className: "fa fa-picture-o",
          title: "이미지 넣기",
        },
        {
          name: "table",
          action: SimpleMDE.drawTable,
          className: "fa fa-table",
          title: "표 그리기"
        },
        {
          name: "horizontal-rule",
          action: SimpleMDE.drawHorizontalRule,
          className: "fa fa-minus",
          title: "가로줄"
        },  '|',
        {
          name: "preview",
          action: SimpleMDE.togglePreview,
          className: "fa fa-eye no-disable",
          title: "미리보기",
        },
        {
          name: "side-by-side",
          action: SimpleMDE.toggleSideBySide,
          className: "fa fa-columns no-disable no-mobile",
          title: "미리 보면서 작성하기",
        }, '|',
        {
          name: "guide",
          action: "https://github.com/parti-xyz/catan-web/wiki/%EB%B9%A0%EB%9D%A0-%EC%9C%84%ED%82%A4-%EB%A7%88%ED%81%AC%EB%8B%A4%EC%9A%B4-%EA%B0%80%EC%9D%B4%EB%93%9C",
          className: "fa fa-question-circle",
          title: "마크다운이란?",
        },
        {
          name: "save",
          action: function(editor) {
            if($.is_present(editor.value())) {
              editor.element.form.submit();
            }
          },
          className: "btn btn-primary btn-sm btn-save-wiki",
          title: "Save"
        },
        {
          name: "취소",
          action: $elm.data('parti-url'),
          className: "link-to-wiki",
          title: "취소",
        },
      ]
    }).toggleFullScreen();
    $('.link-to-wiki').attr('target', null);
  }

  if ( $('#wikis .body .wiki_content a').length ){
    $('#wikis .body .wiki_content a').attr('target', '_blank');
  }
});

// fixed section#issue-bottom-banner
$(function(){
  // Hide Header on on scroll down
  var did_scroll;
  var last_scroll_top = 0;
  var delta = 5;
  var $footer_element = $('section#issue-bottom-banner .bottom-banner');
  var navbar_height = $footer_element.outerHeight();

  $(window).scroll(function(e){
      did_scroll = true;
  });


  if ($("body").height() > $(window).height()) {
    setInterval(function() {
      if (did_scroll) {
        has_scrolled();
        did_scroll = false;
      }
    }, 250);
  }
  else {
    $('body').css('padding-bottom',
      parseInt($('body').css('padding-bottom')) + 60 + 'px');
    $footer_element.removeClass('nav-down').addClass('nav-up');
  }

  function has_scrolled() {
    var st = $(this).scrollTop();

    if(Math.abs(last_scroll_top - st) <= delta)
      return;

    if (st > last_scroll_top && st > navbar_height){
      // Scroll Up
      if(st + $(window).height() <= $(document).height()) {
        $footer_element.removeClass('nav-up').addClass('nav-down');
      }
    } else {
      $footer_element.removeClass('nav-down').addClass('nav-up');
    }

    last_scroll_top = st;
  }

  if(($('#post-modal').data('bs.modal') || {}).isShown) {
    $footer_element.removeClass('nav-up').addClass('nav-down');
    $('#post-modal').data('bs.modal').$backdrop.addClass('post-backdrop');
  }
  $('#post-modal').on('shown.bs.modal', function (e) {
    $footer_element.removeClass('nav-up').addClass('nav-down');
    $('#post-modal').data('bs.modal').$backdrop.addClass('post-backdrop');
  });
  $('#post-modal').on('hidden.bs.modal', function (e) {
    $footer_element.removeClass('nav-down').addClass('nav-up');
  });
});


