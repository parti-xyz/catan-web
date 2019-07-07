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
//= require jquery.ui.position
//= require jquery.contextMenu
//= require jquery-deepest
//= require visibilityChanged

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

// form validation by extern
$.validator.addMethod("extern", function(value, element) {
  return $(element).data('rule-extern-value') === 'valid';
}, function(params, element) {
  return $(element).data('rule-extern-error-message');
});

// form validation by http_url
$.validator.addMethod("http_url", function(value, element) {
  return this.optional(element) || /^(?:(?:(?:https?):)?\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})).?)(?::\d{2,5})?(?:[/?#]\S*)?$/i.test( value );
}, "");

$.validator.addMethod('filesize', function(value, element, param) {
  // param = size (in bytes)
  // element = element to validate (<input>)
  // value = value of the element (file name)
  return this.optional(element) || (element.files[0].size <= param)
});

var __root_domain = $('body').data('root-domain');

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

var parti_prepare_form_validator = function($base) {
  // form validator
  $.parti_apply($base, '[data-action="parti-form-validation"]', function(elm) {
    var $elm = $(elm);
    var $form = $(elm);
    var $submit = $($elm.data("submit-form-control"));
    var $tinymce = $form.find('.js-tinymce');
    var has_tinymce = ($tinymce.length > 0);

    if(has_tinymce) {
      $form.on('submit', function(e) {
        $tinymce.trigger('parti-tinymce-conflict');
        var content = tinyMCE.get($tinymce.attr('id')).getContent();
        $($tinymce.data('target-id')).val(content);
      });
    } else {
      $submit.prop('disabled', true);
    }

    $form.validate({
      ignore: ':hidden:not(.validate)',
      errorPlacement: function(error, element) {
        return true;
      },
      invalidHandler: function(event, validator) {
        if(!has_tinymce) {
          return true;
        } else {
          var errors = validator.numberOfInvalids();
          if(errors) {
            var successList = validator.successList;
            $.each(successList, function(index, element) {
              var _popover;
              var $popover_target = $($(element).data('error-popover-target'));
              if($popover_target.length <= 0) {
                $popover_target = $(element);
              }
              return $popover_target.popover("hide");
            });

            var focused = false;

            var errorList = validator.errorList;
            return $.each(errorList, function(index, value) {
              if(!focused && !$(value.element).data('prevent-focus-invalid')) {
                $(value.element).focus();
                focused = true;
              }

              var _popover;
              var $popover_target = $($(value.element).data('error-popover-target'));
              if($popover_target.length <= 0) {
                $popover_target = $(value.element);
              }
              _popover = $popover_target.popover({
                trigger: "manual",
                placement: "bottom",
                content: value.message,
                template: "<div class=\"popover error-popover\"><div class=\"arrow\"></div><div class=\"popover-inner\"><div class=\"popover-content text-basic-wrap\"><p></p></div></div></div>"
              });
              _popover.data("bs.popover").options.content = value.message;

              setTimeout(function() { $popover_target.popover("hide"); }, 3000);
              if(index == 0) {
                var $scrollTarget = $(window);
                var $scrollTargetModal = $(value.element).closest('.modal');
                if($(value.element).closest('.modal').length > 0) {
                  $scrollTarget = $scrollTargetModal;
                }
                $scrollTarget.scrollTo($popover_target, 100, { offset: -100, onAfter: function(target, settings) {
                  return $popover_target.popover("show");
                } } );
              } else {
                setTimeout(function() { $popover_target.popover("show"); }, 100);
              }
            });
          }
        }
      },
      focusInvalid: false
    });

    var enabling_callback = function() {
      $submit.prop('disabled', false);
      $submit.removeClass('collapse');
      $submit.parent().removeClass('collapse');
    }

    if(!has_tinymce) {
      if($form.valid()) {
        enabling_callback($submit);
      }

      $elm.find(':input').on('input', function(e) {
        if($form.valid()) {
          enabling_callback();
        } else {
          $submit.prop('disabled', true);
        }
      });

      $elm.find(':input').on('change', function(e) {
        if($form.valid()) {
          enabling_callback();
        } else {
          $submit.prop('disabled', true);
        }
      });

      $elm.find('select').on('change', function(e) {
        if($form.valid()) {
          enabling_callback();
        } else {
          $submit.prop('disabled', true);
        }
      });

      $elm.find(':input').on('parti-need-to-validate', function(e) {
        if($form.valid()) {
          enabling_callback();
        } else {
          $submit.prop('disabled', true);
        }
      });

      $elm.on('parti-need-to-validate', function(e) {
        if($form.valid()) {
          enabling_callback();
        } else {
          $submit.prop('disabled', true);
        }
      });
    }
  });
}

var parti_prepare = function($base, force) {
  if(!force && $base.data('parti-prepare-arel') == 'completed') {
    return;
  }

  parti_prepare_form_validator($base);

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

  // form submit by clicking link
  $.parti_apply($base, '[data-action="parti-form-submit"]', function(elm) {
    if(ufo.isApp()
      && $(elm).data('mobile-app-handler') && ufo.canHandle($(elm).data('mobile-app-handler'))
      && $(elm).data('mobile-app-url')) {
      $(elm).on('click', function(e) {
        window.location.href = $(elm).data('mobile-app-url');
      });
    } else {
      $(elm).on('click', function(e) {
        $('[data-action="parti-form-submit"]').attr('disabled', true);
        e.preventDefault();
        var $elm = $(e.currentTarget);
        var $form = $($elm.data('form-target'));
        var url = $elm.data('form-url');
        if(url) {
          $form.attr('action', url);
        }
        $form.submit();
      });
    }
  });

  // form set value
  $.parti_apply($base, '[data-action="parti-form-set-vaule"]', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();
      var $elm = $(e.currentTarget);
      var $control = $($elm.data('form-control'));
      var value = $elm.data('form-vaule');
      $control.val(value);
      $control.trigger("blur");
    });
  });

  // autoresize toggle
  $.parti_apply($base, '.js-autoresize', function(elm) {
    autosize($(elm));
  });

  //new posts count
  $.parti_apply($base, '[data-action="parti-polling"]', function(elm) {
    var $elm = $(elm);
    var polling_url = $(elm).data("polling-url");
    var polling_interval_initial = $(elm).data("polling-interval-initial");
    var polling_interval_increment = $(elm).data("polling-interval-increment");

    var polling_interval = parseInt(polling_interval_initial) || 5 * 60 * 1000;

    var updated_posts = function() {
      if($elm.is(':visible')) {
        polling_interval += parseInt(polling_interval_increment) || 5 * 60 * 1000;
        polling_interval = Math.min(polling_interval, 60 * 60 * 1000);
      }

      $.getScript(polling_url);
      setTimeout(updated_posts, polling_interval);
    }
    setTimeout(updated_posts, polling_interval);
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

  $.parti_apply($base, '[data-action="parti-filter-parties"]', function(elm) {
    var $elm = $(elm);
    $elm.on('click', function(e) {
      var search_form = $(this).data('search-form');
      var sort = $(this).data('search-sort');
      var category_id = $(this).data('search-category-id');
      var $elm = $(this);

      $(search_form).find("input[name='sort']").val(sort);
      $(search_form).find("input[name='category_id']").val(category_id);
      $(search_form).submit();
      return false;
    });
  });

  // 에디터 파일 추가/삭제 버튼
  $.parti_apply($base, '.js-post-editor-file_sources-wrapper', function(elm) {
    $(elm).on('cocoon:after-insert',function (e, item){
      item.find("input[type='file']").trigger('click');
    });

    $(elm).on('cocoon:after-remove',function (e, item){
      var $form = $(e.currentTarget).closest('form');
      var has_image = false;
      $form.find(".js-form-group-images input[type='file']").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_image = true; }
      });
      $form.find(".js-form-group-images input.js-id").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_image = true; }
      });

      if(!has_image) {
        $form.find('.js-form-group-images').removeClass('js-any');
      }

      var has_file = false;
      $form.find(".js-form-group-files input[type='file']").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_file = true; }
      });
      $form.find(".js-form-group-files input.js-id").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_file = true; }
      });

      if(!has_file) {
        $form.find(".js-form-group-files").removeClass('js-any');
      }

      $form.trigger('parti-form-after-removing-attachment-input');
    });
  });

  // 체크박스에 따라 폼이 숨겨지거나 보이게 하기
  $.parti_apply($base, '.js-hider-checkbox', function(elm) {
    $(elm).on('change', function(e) {
      var $form = $(e.currentTarget).closest('form');
      var $checked = $form.find($(e.currentTarget).data('hider-checkbox-checked'));
      var $unchecked = $form.find($(e.currentTarget).data('hider-checkbox-unchecked'));

      if($(e.currentTarget).is(":checked")) {
        $checked.hide();
        $unchecked.show();
      } else {
        $checked.show();
        $unchecked.hide();
      }
    });
  });

  // 선택박스에 따라 폼이 숨겨지거나 보이게 하기
  $.parti_apply($base, '.js-toggle-select', function(elm) {
    $(elm).on('change', function(e) {
      var $container = $($(elm).data('toggle-select-container'));
      if($container.length <= 0) {
        $container = $(e.currentTarget).closest('form');
      }

      $(e.currentTarget).find(":selected").each(function(index, option_elm) {
        var $showing_elm = $container.find($(option_elm).data('js-toggle-select-show'));
        var $hiding_elm = $container.find($(option_elm).data('js-toggle-select-hide'));

        $hiding_elm.hide();
        $showing_elm.show();
      });
    });
  });

  $.parti_apply($base, '.js-group-editor-selector', function(elm) {
    $(elm).selectpicker('render');
    $(elm).on('loaded.bs.select', function(e) {
      $(this).show();
    });
  });

  // 게시글 쓸때 채널 선택하기
  $.parti_apply($base, '.js-parti-editor-selector', function(elm) {
    $elm = $(elm);

    $elm.selectpicker('render');
    $elm.parent().on('hide.bs.select', function(e) {
      var $form = $elm.closest('.js-parti-editor-selector-wrapper').find('form.js-parti-editor-selector-form');

      var $input_elm = $form.find('input[name*="[issue_id]"]');
      var select_value = $elm.val();
      $input_elm.val(select_value);
      $input_elm.trigger('parti-need-to-validate');

      var $selected_option = $elm.find(":selected");
      if($selected_option) {
        var $pin_check_box_wrapper = $form.find('.js-post-form-pin-button');
        if($selected_option.data('can-pin') == true) {
          $pin_check_box_wrapper.css('display', 'inline-block');
        } else {
          $pin_check_box_wrapper.css('display', 'none');
        }

        var $event_button = $form.find('.js-post-form-experiment');
        if($selected_option.data('can-experiment') == true) {
          $event_button.show();
        } else {
          $event_button.hide();
          $form.find('.js-post-form-experiment-cancel-button:visible').map(function(index, elm) {
            $elm.trigger('click');
          });
        }
      }
    });

    $elm.on('changed.bs.select', function (e, clickedIndex, isSelected, previousValue) {
      var $select_box = $(e.currentTarget);
      var $form = $(e.currentTarget).closest('.js-parti-editor-selector-wrapper').find('form.js-parti-editor-selector-form');
      var $pin_check_box = $form.find('.js-post-form-pin-button input[type="checkbox"]');
      $pin_check_box.prop('checked', false);
    });

    $elm.on('loaded.bs.select', function(e) {
      $(this).show();
    });
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
      $(trigger_target).trigger(trigger_name);
    });
  });

  // 게시글 쓸때 투표 등을 선택하기
  $.parti_apply($base, '.js-post-select-subform', function(elm) {
    var $elm = $(elm);
    var reference_field = $elm.data('reference-field');
    var has_poll = $elm.data('has-poll');
    var has_survey = $elm.data('has-survey');
    var has_event = $elm.data('has-event');
    var $form = $elm.closest('form');

    var callback = function (e){
      e.preventDefault();
      if($(reference_field).hasClass('hidden')){
        $(reference_field).removeClass('hidden');
      }
      if($elm.hasClass('js-post-poll-btn')){
        $('.js-post-poll-btn').hide();
        $('.js-post-survey-btn').hide();
        $('.js-post-event-btn').hide();
        $(has_poll).val(true);
      } else if($elm.hasClass('js-post-survey-btn')){
        $('.js-post-poll-btn').hide();
        $('.js-post-survey-btn').hide();
        $('.js-post-event-btn').hide();
        $(has_survey).val(true);
      } else if($elm.hasClass('js-post-event-btn')){
        $('.js-post-poll-btn').hide();
        $('.js-post-survey-btn').hide();
        $('.js-post-event-btn').hide();
        $(has_event).val(true);
      } else if($elm.hasClass('js-post-file-btn')) {
        $('.js-post-file-btn').hide();
        $form.find('.js-post-editor-file_sources-add-btn > a').trigger('click');
      } else if($elm.hasClass('js-post-wiki-btn')) {
        var url = $elm.data('url');
        if(url) {
          var $input_elm = $('form.form-widget input[name*="[issue_id]"]');
          if($input_elm && $input_elm.val()) {
            url = url + '?issue_id=' + $input_elm.val();
          }
          window.open(url, '_blank');
        }
      }
      $elm.closest('[data-action="parti-form-validation"]').trigger('parti-need-to-validate');
    }

    $elm.on('click', callback);
    $elm.on('parti-post-select-subform', function(e) {
      $('.js-post-editor-intro').trigger('parti-post-editor-intro');
      callback(e);
    });
  });

  $.parti_apply($base, '[data-action="parti-post-cancel-subform"]', function(elm) {
    $(elm).on('click',function(e){
      e.preventDefault();

      $target = $(e.currentTarget);

      var reference_field = $target.data('reference-field');
      var has_poll = $target.data('has-poll');
      var has_survey = $target.data('has-survey');
      var has_event = $target.data('has-event');
      var $file_sources = $($target.data('file-sources'));

      $(reference_field).addClass('hidden');
      $('.js-post-poll-btn').show();
      $('.js-post-survey-btn').show();
      $('.js-post-event-btn').show();
      $('.js-post-file-btn').show();
      $(has_poll).val(false);
      $(has_survey).val(false);
      $(has_event).val(false);
      $file_sources.remove();
      var $form = $target.closest('form');
      $form.find('.js-post-editor-file_sources-add-btn .js-current-count').text('0');

      $target.closest('[data-action="parti-form-validation"]').trigger('parti-need-to-validate');

      return false;
    });
  });

  // bootstrap select
  $.parti_apply($base, '.js-parti-bootstrap-select', function(elm) {
    $(elm).selectpicker('render');
  });

  // search
  $.parti_apply($base, '.js-header-search', function(elm) {
    var $elm = $(elm);

    var hide_menu = function() {
      $elm.find('.js-header-search-dropdown-item').hide();
      $elm.find('.js-header-search-dropdown').hide();
    }

    var show_menu = function() {
      $elm.find('.js-header-search-dropdown-item').removeClass('active');

      $elm.find('.js-header-search-dropdown-item[data-header-search-type="all"]').show();
      var active = 'all';
      if(_current_group_id()) {
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="group"]').show();
        active = 'group';
      } else {
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="group"]').hide();
      }
      if(_current_issue_id()) {
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="issue"]').show();
        active = 'issue';
      } else {
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="issue"]').hide();
      }
      $elm.find('.js-header-search-dropdown-item[data-header-search-type="' + active + '"]').addClass('active');
      $elm.find('.js-header-search-dropdown').show();
    }

    $elm.on('input', '.js-header-search-input', _.throttle(function(e) {
      $input = $(e.currentTarget);
      $elm.find('.js-header-search-dropdown-value').text($input.val());
      if($.is_blank($input.val())) {
        hide_menu();
      } else {
        show_menu();
      }
    }, 200));

    $elm.on('focus', '.js-header-search-input', function(e) {
      $(e.currentTarget).trigger('input');
    });

    $elm.on('blur', '.js-header-search-input', function(e) {
      setTimeout(hide_menu, 1000);
    });

    $elm.on('mouseenter', '.js-header-search-dropdown-item', function(e) {
      $elm.find('.js-header-search-dropdown-item').removeClass('active');
      $(e.currentTarget).addClass('active');
    });

    $elm.on('click', '.js-header-search-dropdown-item', function(e) {
      e.preventDefault();
      if($.is_blank($elm.find('.js-header-search-input').val())) {
        alert('찾을 단어를 입력하세요.');
        return;
      }
      $elm.find('input[name="search_type"]').val($(e.currentTarget).data('header-search-type'));
      $elm.find('input[name="group_id"]').val(_current_group_id());
      $elm.find('input[name="issue_id"]').val(_current_issue_id());
      $elm.submit();
    });

    $elm.on('submit', function(e) {
      var current_search_type = $elm.find('input[name="search_type"]').val();
      if($.is_blank(current_search_type)) {
        $elm.find('input[name="search_type"]').val('all');
        if(_current_group_id()) {
          $elm.find('input[name="group_id"]').val(_current_group_id());
          $elm.find('input[name="search_type"]').val('group');
        }
        if(_current_issue_id()) {
          $elm.find('input[name="issue_id"]').val(_current_issue_id());
          $elm.find('input[name="search_type"]').val('issue');
        }
      }
    });
  });

  $.parti_apply($base, '.js-mobile-header-search', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();
      var href = $(e.currentTarget).attr('href');
      href += '?group_id=' + _current_group_id();
      href += '&issue_id=' + _current_issue_id();
      location.href = href;
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

  // 에디터

  // editor
  (function() {
    //plugins: 'image media link paste contextmenu textpattern autolink',
    var settings = {
      default: {
        plugins: 'stickytoolbar link paste autolink autosave lists advlist autoresize hot-style',
        toolbar: 'bold italic strikethrough | link blockquote style-p style-h1 style-h2 style-h3 | bullist numlist outdent indent',
        forced_root_block: 'div',
      },
      wiki: {
        plugins: 'stickytoolbar link paste autolink autosave lists advlist autoresize hot-style',
        toolbar: 'bold italic strikethrough | link blockquote style-br style-p style-h1 style-h2 style-h3 |  bullist numlist outdent indent',
        forced_root_block: 'p',
      },
    };
    $.parti_apply($base, '.js-tinymce:not(.js-tinymce-mobile)', function(elm) {
      var $elm = $(elm)
      var setting_name = $elm.data('tinymce-setting');
      var setting = settings.default;
      if(setting_name) {
        setting = settings[setting_name];
      }
      var content_css = $elm.data('content-css');

      var tinymce_instance = $elm.tinymce({
        cache_suffix: '?v=5.0.5.4',
        language: 'ko_KR',
        plugins: setting.plugins,
        menubar: false,
        min_height: 200,
        forced_root_block : setting.forced_root_block,
        autoresize_bottom_margin: 0,
        statusbar: false,
        toolbar: setting.toolbar,
        paste_data_images: true,
        document_base_url: 'https://parti.xyz/',
        link_context_toolbar: true,
        target_list: false,
        relative_urls: false,
        remove_script_host : false,
        hidden_input: false,
        uploadimage_default_img_class: 'tinymce-content-image',
        content_css: content_css,
        formats: {
          strikethrough: {inline : 'del'}
        },
        sticky_offset: 51,
        valid_classes: '',
        valid_styles: '',
        extended_valid_elements : 'div,span,diffremoved,diffadded',
        custom_elements : '~diffremoved,~diffadded',
      });

      $elm.on('parti-tinymce-conflict', function(e) {
        var content = tinyMCE.get($elm.attr('id')).getContent();
        var $content =$('<content>' + content + '</content>');
        $content.find('diffadded').contents().unwrap();
        $content.find('diffremoved').contents().unwrap();
        $content.find('difftouched').contents().unwrap();
        tinyMCE.get($elm.attr('id')).setContent($content.html());
      });
    });

    settings = {
      default: {
        plugins: 'link paste autolink lists advlist autoresize stickytoolbar-mobile hot-style',
        toolbar: 'bold italic strikethrough link blockquote style-p | style-h1 style-h2 style-h3 bullist numlist outdent indent',
        forced_root_block: 'div',
      },
      wiki: {
        plugins: 'link paste autolink lists advlist autoresize stickytoolbar-mobile hot-style',
        toolbar: 'bold italic strikethrough link blockquote style-br style-p style-h1 style-h2 style-h3 bullist numlist outdent indent',
        forced_root_block: 'p',
      },
    };
    // Tinymce on mobile
    $.parti_apply($base, '.js-tinymce.js-tinymce-mobile', function(elm) {
      $elm = $(elm);
      var setting_name = $elm.data('tinymce-setting');

      var setting = settings.default;
      if(setting_name) {
        setting = settings[setting_name];
      }
      var content_css = $elm.data('content-css');

      $elm.tinymce({
        cache_suffix: '?v=5.0.5.4',
        language: 'ko_KR',
        plugins: setting.plugins,
        menubar: false,
        min_height: 300,
        autoresize_bottom_margin: 0,
        forced_root_block : setting.forced_root_block,
        statusbar: false,
        toolbar: setting.toolbar,
        toolbar_drawer: 'sliding',
        paste_data_images: true,
        extended_valid_elements: 'span',
        document_base_url: 'https://parti.xyz/',
        link_context_toolbar: false,
        target_list: false,
        relative_urls: false,
        remove_script_host : false,
        hidden_input: false,
        uploadimage_default_img_class: 'tinymce-content-image',
        content_css: content_css,
        formats: {
          strikethrough: {inline : 'del'}
        },
        mobile: {
          theme: 'silver'
        },
        valid_classes: '',
        valid_styles: '',
        extended_valid_elements : 'span,diffremoved,diffadded',
        custom_elements : '~diffremoved,~diffadded',
        setup: function (editor) {
          // link opender
          editor.on('init', function(){
            var $link_opener = $('<div class="js-tinymce-catan-link-opener tinymce-catan-link-opener"></div>');
            var container = editor.editorContainer;
            var $edit_area = $(container).find('.tox-edit-area');
            $edit_area.prepend($link_opener);
            $link_opener.hide();
          });

          var oldScrollTop;
          editor.on('OpenWindow', function(){
            var toolbar = $('.tox-toolbar')[0];
            oldScrollTop = toolbar.getBoundingClientRect().top;
            setTimeout(function() {
              $.scrollTo(0, 0);
            }, 500);
          });
          editor.on('CloseWindow', function(){
            if (oldScrollTop) {
              setTimeout(function() {
                $.scrollTo(oldScrollTop, 0);
                oldScrollTop = null;
              }, 500);
            }
          });

          // virtual keyboard
          editor.on('focus', function (e) {
            $(document).trigger('parti-ios-virtaul-keyboard-open-for-tinymce');
          });
        },
        init_instance_callback: function (editor) {
          editor.on('NodeChange', function (e) {
            var container = editor.editorContainer;
            var $toolbars = $(container).find('.tox-edit-area');
            var $link_opener = $toolbars.find('.js-tinymce-catan-link-opener');

            var node = tinyMCE.activeEditor.selection.getNode();
            var href = $(node).attr('href');
            if($.is_blank(href)) {
              $link_opener.html('');
              $link_opener.hide();
            } else {
              $link_opener.html('<a href="' + href + '" target="_blank"><i class="fa fa-external-link" /> ' + href + '</a>');
              $link_opener.stop().slideDown();
            }
          });
          editor.on('Change', function (e) {
            Waypoint.refreshAll();
          });
        }
      });

      $elm.on('parti-tinymce-conflict', function(e) {
        var content = tinyMCE.get($elm.attr('id')).getContent();
        var $content =$('<content>' + content + '</content>');
        $content.find('diffadded').contents().unwrap();
        $content.find('diffremoved').contents().unwrap();
        $content.find('difftouched').contents().unwrap();
        tinyMCE.get($elm.attr('id')).setContent($content.html());
      });
    });
  })();

  // mention
  $.parti_apply($base, '.js-mention:hidden', function(elm) {
    var $control = $($(elm).data('comment-form-control'));
    if ($control.length > 0) {
      $(elm).show();
    }
  });

  $.parti_apply($base, '.js-mention', function(elm) {
    var $elm = $(elm);
    $elm.on('click', function(e) {
      e.preventDefault();
      var $target = $(e.currentTarget);

      parti_prepare_comment($target.data('comment-form-control'), $target.data('mention-nickname'), $target.data('mention-text'));
    });
  });

  // file upload form sortable
  $.parti_apply($base, '.js-form-group-images', function(elm) {
    Sortable.create(elm);
  });
  $.parti_apply($base, '.js-form-group-files', function(elm) {
    Sortable.create(elm);
  });

  // form dirty check
  $.parti_apply($base, '.js-dirty-form', function(elm) {
    var $elm = $(elm);
    $elm.dirrty();

    $(document).on('submit.rails', $.rails.formSubmitSelector, function(e) {
      var $form = $(this);
      if ($elm != $form && !$.rails.isRemote($form)) {
        $elm.dirrty("setClean");
      }
    });

    $(document).on('click.rails', $.rails.linkClickSelector, function(e) {
      var $link = $(this);
      if (!$.rails.isRemote($link)) {
        $(elm).dirrty("setClean");
      }
    });
  });

  // 댓글 읽기
  (function() {
    var __cached_comment_reader = [];

    $.parti_apply($base, '.js-comments-reader', function(elm) {
      var $elm = $(elm);
      $elm.find('.js-comments-reader-mark').waypoint({
        handler: function(direction) {
          if(direction == 'down') {
            var comment_ids = [];
            $elm.find('.js-comment-reader-line').each(function(index) {
              var comment_id = $(this).data('comment-id');
              if(comment_id) {
                if(_.indexOf(__cached_comment_reader, comment_id) == -1) {
                  comment_ids.push(comment_id);
                  __cached_comment_reader.push(comment_id);
                }
              }
            });

            if(comment_ids.length > 0) {
              $.ajax({
                url: $elm.data('url'),
                type: "post",
                data:{ 'comment_ids': _.join(comment_ids, ',') }
              });
            }
          }
        },
        offset: "100%"
      });
    });
  })();

  // 모두 읽음 표시 업데이트
  (function() {
    $.parti_apply($base, '.js-read-all-posts', function(elm) {
      var $elm = $(elm);
      var waypoint = $elm.waypoint({
        handler: function(direction) {
          if(direction == 'down') {
            $.ajax({
              url: $elm.attr('href'),
              type: "post",
              data:{ 'auto': 'true' }
            });
          }
        },
        offset: "100%"
      });
      $elm.on('parti-read-all-posts-destroy', function(e) {
        if(waypoint) {
          waypoint.forEach(function(item){
            item.destroy();
          });
          waypoint = null;
        }
      });
    });
  })();

  $.parti_apply($base, '.js-hover-toggle', function(elm) {
    $(elm).hover(function(e) {
      $($(elm).data('hover-toggle')).show();
    }, function(e) {
      $($(elm).data('hover-toggle')).hide();
    });
  });

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

        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues = $group.find('.js-sidemenu-toggle-issues');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        if($issues.hasClass('js-sidemenu-toggle-issues-fold-temporary')) {
          $('.js-drawer-filter').trigger('parti-drawer-filter-temporary-reset', $issues);
          $issues.addClass('js-sidemenu-toggle-issues-unfold-temporary');
          $issues.removeClass('js-sidemenu-toggle-issues-fold-temporary');
          $icon.removeClass(unfold_icon);
          $icon.addClass(fold_icon);
        } else if($issues.hasClass('js-sidemenu-toggle-issues-unfold-temporary')) {
          $('.js-drawer-filter').trigger('parti-drawer-filter-temporary-ignore', $issues);
          $issues.removeClass('js-sidemenu-toggle-issues-unfold-temporary');
          $issues.addClass('js-sidemenu-toggle-issues-fold-temporary');
          $icon.removeClass(fold_icon);
          $icon.addClass(unfold_icon);
        } else {
          var mode;
          if(force_mode) {
            mode = force_mode;
          } else {
            mode = ($issues.is(':visible') ? 'fold' : 'unfold');
          }

          var group_id = 0;
          var group_id_str = $group.data('sidemenu-toggle-group-id');
          if(group_id_str) {
            group_id = parseInt(group_id_str);
          }

          if(mode == 'fold') {
            $issues.addClass('js-sidemenu-toggle-issues-fold');
            $issues.removeClass('js-sidemenu-toggle-issues-unfold');
            $issues.hide();

            $icon.removeClass(unfold_icon);
            $icon.addClass(fold_icon);
          } else {
            $issues.removeClass('js-sidemenu-toggle-issues-fold');
            $issues.addClass('js-sidemenu-toggle-issues-unfold');
            $issues.show();

            $icon.removeClass(fold_icon);
            $icon.addClass(unfold_icon);
          }
        }
      });

      $(elm).on('parti-sidemenu-toggle-reinit', function(e) {
        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues = $group.find('.js-sidemenu-toggle-issues');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        if($issues.hasClass('js-sidemenu-toggle-issues-fold')) {
          $issues.hide();

          $icon.removeClass(unfold_icon);
          $icon.addClass(fold_icon);
        } else {
          $issues.show();

          $icon.removeClass(fold_icon);
          $icon.addClass(unfold_icon);
        }
        $issues.removeClass('js-sidemenu-toggle-issues-fold-temporary');
        $issues.removeClass('js-sidemenu-toggle-issues-unfold-temporary');
      });

      $(elm).on('parti-sidemenu-toggle-show-temporary', function(e) {
        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues = $group.find('.js-sidemenu-toggle-issues');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        $issues.addClass('js-sidemenu-toggle-issues-unfold-temporary');
        $issues.removeClass('js-sidemenu-toggle-issues-fold-temporary');
        $issues.show();

        $icon.removeClass(unfold_icon);
        $icon.addClass(fold_icon);
      });

      $(elm).on('parti-sidemenu-toggle-hide-temporary', function(e) {
        e.preventDefault();
        var $target = $(e.currentTarget);
        var $group = $target.closest('.js-sidemenu-toggle-group');
        var $issues = $group.find('.js-sidemenu-toggle-issues');
        var $icon = $group.find('.js-sidemenu-toggle-icon');

        $issues.addClass('js-sidemenu-toggle-issues-unfold-temporary');
        $issues.removeClass('js-sidemenu-toggle-issues-fold-temporary');
        $issues.show();

        $icon.removeClass(unfold_icon);
        $icon.addClass(fold_icon);
      });
    });
  })();


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

  var _current_issue_id = function() {
    var $current_parti_source = $('.js-sidemenu-highlight-current-parti-source');
    var current_parti_id = '';
    if($current_parti_source.length > 0) {
      current_parti_id = $current_parti_source.data('sidemenu-highlight-current-parti-id');
    }

    return current_parti_id;
  }

  var _current_group_id = function() {
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

  $.parti_apply($base, '.js-lazy-partal-load-drawer', function(elm) {
    $.ajax({
      url: $(elm).data('url'),
      type: 'get',
      crossDomain: false,
      data:{
        issue_id: _current_issue_id(),
        group_id: _current_group_id(),
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

  // 폴더 목록의 폴더나 아이템 클릭/더블클릭
  (function() {
    var delay = 700;

    $.parti_apply($base, '.js-folder-item', function(elm) {
      var $elm = $(elm);
      var $rename_form_elm = $elm.find('.js-folder-item-rename-form');
      var $rename_title_field_elm = $elm.find('.js-folder-item-rename-text-field');
      var $content_elm = $elm.find('.js-folder-item-renamable-content');

      var esc_handler = function(e) {
        if (e.keyCode == 27) { // escape key maps to keycode `27`
          on_blur();
        }
      }

      var on_blur = function(e) {
        $(document).off('keyup.folder-item', esc_handler);
        $rename_title_field_elm.off('blur.folder-item', on_blur);

        reset_item($elm, true);
        $elm.addClass('js-blured');
        setTimeout(function() {
          $elm.removeClass('js-blured');
        }, 1000);
      }

      var reset_item = function($current_elm, active) {
        $current_elm.data('timeout', null);
        $current_elm.data('clicks', 0);
        $current_elm.find('.js-folder-item-rename-form').hide();
        $current_elm.find('.js-folder-item-renamable-content').show();

        if(!active) {
          $current_elm.removeClass('active');
        }
        $current_elm.removeClass('js-try-to-rename');
        $current_elm.removeClass('js-renaming');
        $current_elm.removeClass('js-blured');
      }

      var text_field_width = function(text) {
        var original_text = $content_elm.text();

        $content_elm.text(text);
        var buffer = 8;
        var text_width = $content_elm.outerWidth() - buffer;
        $content_elm.text(original_text);

        var parent_width = $content_elm.parent().outerWidth() - buffer;
        return Math.min(text_width, parent_width);
      }

      var on_run = function(e) {
        clearTimeout($elm.data('timeout')); //prevent single-click action

        if($elm.data('folder-item-type') === 'folder') {
          $elm.siblings('.js-folder-children').slideToggle(100, function() {
            var _cookies_folder_ids = Cookies.getJSON('opened_folder_ids') || [];
            var folder_id = $elm.data('folder-item-id');

            if($(this).is(':visible')) {
              $elm.find('.js-folder-item-icon').removeClass('fa-folder').addClass('fa-folder-open');
              _cookies_folder_ids.push(folder_id);
            } else {
              $elm.find('.js-folder-item-icon').removeClass('fa-folder-open').addClass('fa-folder');
              _.pull(_cookies_folder_ids, folder_id);
            }
            _cookies_folder_ids = _.uniq(_cookies_folder_ids);
            if(_cookies_folder_ids.length > 2000) {
              _cookies_folder_ids.shift()
            }
            Cookies.set('opened_folder_ids', _cookies_folder_ids, { domain: '.' + __root_domain, expires: 7 });
          });
        }
        if($elm.data('folder-item-type') === 'post') {
          e.preventDefault();
          var url = $elm.data("url");
          if(!url) { return; }

          if (e.shiftKey || e.ctrlKey || e.metaKey) {
            window.open(url, '_blank');
          } else {
            window.location.href  = url;
          }
        }
        reset_item($elm, true); //after action performed, reset counter
      }

      var on_rename = function() {
        var title = $content_elm.data('value');
        $rename_title_field_elm.val(title).trigger('input');
        $rename_form_elm.show();
        $content_elm.hide();

        $elm.removeClass('js-try-to-rename');
        $elm.addClass('js-renaming');

        $(document).on('keyup.folder-item', esc_handler);
        $rename_title_field_elm.on('blur.folder-item', on_blur);

        $rename_title_field_elm.focus();
        $rename_title_field_elm[0].setSelectionRange(0, 0);
        $rename_title_field_elm[0].scrollLeft = 0
      }

      $elm.on('dblclick', function(e) {
        e.preventDefault();
      });

      $elm.on('click', function(e) {
        if($.breakpoint_max() === "xs") {
          reset_item($elm);
          on_run(e);
          return;
        }

        $elm.data('clicks', ($elm.data('clicks') || 0) + 1);

        $('.js-folder-item').each(function(index, current_elm) {
          if(!$(current_elm).is($elm)) {
            reset_item($(current_elm));
          }
        });

        if($elm.hasClass('js-blured')) {
          $elm.removeClass('js-blured');
          $elm.data('clicks', 0);
          return;
        }

        if($elm.hasClass('js-renaming')) {
          $elm.data('clicks', 0);
          return;
        }

        if($elm.hasClass('active')) {
          if($elm.hasClass('js-folder-item-managable')) {
            $elm.addClass('js-try-to-rename');
          }
        } else {
          $elm.addClass('active');
          var item_type = $elm.data('folder-item-type');
          var item_id = $elm.data('folder-item-id');
          Cookies.set('latest_active_folder_item', item_type + '#' + item_id, { domain: '.' + __root_domain, expires: 7 });
        }

        if($elm.data('clicks') === 1) {
          $elm.data('timeout', setTimeout(function() {
            $elm.data('timeout', null);
            if($elm.hasClass('js-try-to-rename')) {
              on_rename();
            }
            $elm.data('clicks', 0); //after action performed, reset counter
          }, delay));
        } else {
          on_run(e);
        }
      });

      $elm.on('parti-folder-item-force-active', function(e, data) {
        $('.js-folder-item').each(function(index, current_elm) {
          reset_item($(current_elm));
        });

        $elm.addClass('active');
      });

      $elm.on('parti-folder-item-force-rename', function(e, data) {
        $elm.on('parti-folder-item-force-active');
        on_rename();
      });

      $elm.on('parti-folder-item-saved', function(e, data) {
        var title = data.title;
        $content_elm.data('value', title);
        $content_elm.text(title);
        $rename_title_field_elm.val(title).trigger('input');
        on_blur();
      });

      $elm.on('parti-folder-item-reset', function(e) {
        var title = $content_elm.data('value');
        $content_elm.text(title);
        $rename_title_field_elm.val(title).trigger('input');
        on_blur();
      });

      $rename_form_elm.on('submit', function(e) {
        $elm.trigger('parti-folder-item-saving');
        var title = $rename_title_field_elm.val();
        $content_elm.html(title + ' <i class="fa fa-spinner fa-pulse">');
        on_blur();
      });

      $rename_title_field_elm.on('input', function(e) {
        var width = text_field_width($rename_title_field_elm.val());
        $rename_title_field_elm.css({ width: width });
      }).trigger('input');
    });
  })();

  // 폴더 목록의 폴더나 아이템 드래그앤드롭
  (function() {
    var $current_placeholder;
    var old_container;

    var onKeyDown = function(e) {
      if(e.keyCode == 27) {
        if($current_placeholder) {
          $current_placeholder.remove();
          $current_placeholder = undefined;
        }
        $(this).mouseup();
      }
    }

    $.parti_apply($base, '.js-draggable-slug-folder', function(base_elm) {
      var payload_json = undefined;
      var $base_elm = $(base_elm);

      var autosave_payload = function(params) {
        $('.js-slug-folder-autosave').text('저장 중...');
        submit_payload(params);
      }

      var submit_payload = function(params) {
        if(!!$base_elm.data('url') && !!$base_elm.data('issue-id') && !!payload_json) {
          $.ajax({
            url: $base_elm.data('url'),
            type: "post",
            data:{ issue_id: $base_elm.data('issue-id'), 'payload': payload_json, 'item_type': params.item_type, 'item_id': params.item_id },
          });
        };
      };

      var depth = function($draggable_item) {
        if($draggable_item.find('.js-draggable-slug-folder-container').length > 0) {
          return $draggable_item.deepest('.js-draggable-slug-folder-container').first()
            .parentsUntil($draggable_item, '.js-draggable-slug-folder-container').length + 1;
        } else {
          return 0;
        }
      }

      var max_depth = 2;

      var on_resize = _.debounce(function(e) {
        var group = $base_elm.data('sortable-group');
        if(group) {
          if($.breakpoint_max() === 'xs') {
            group.sortable('disable');
          } else {
            group.sortable('enable');
          }
        }
      }, 1000 * 2);

      var init_group = function() {
        if($base_elm.data('sortable-group')) {
          return;
        }

        $('body').removeClass('draggable-slug-folder-dropping');

        var group = $base_elm.sortable({
          group: 'draggable-slug-folder',
          pullPlaceholder: true,
          containerPath: '', // The exact css path between the container and its item
          containerSelector: '.js-draggable-slug-folder-container',
          itemSelector: '.js-draggable-slug-folder-draggable', // The exact css path between the item and its subcontainers.
          bodyClass: 'draggable-slug-folder-dragging',
          draggedClass: 'draggable-slug-folder-dragged',
          placeholderClass: 'draggable-slug-folder-placeholder',
          placeholder: '<div class="draggable-slug-folder-placeholder collapse"></div>',
          afterMove: function($placeholder, container, $closestItemOrContainer) {
            $current_placeholder = $placeholder;

            if(old_container != container || !container.el.parent().addClass("dragging_active")){
              $('.dragging_active').removeClass("dragging_active");
              container.el.parent().addClass("dragging_active");
              old_container = container;
            }
          },
          onDragStart: function($item, container, _super, event) {
            $(document).on('keydown', onKeyDown);
            _super($item, container);
          },
          onDrag: function($item, position, _super, event) {
            _super($item, position);
          },
          onDrop: function($item, container, _super, event) {
            if(!container) {
              return;
            }

            $(document).off('keydown', onKeyDown);
            $('.dragging_active').removeClass("dragging_active");

            if(!$current_placeholder) {
              _super($item, container);
              return;
            }
            $current_placeholder = undefined;

            $('.js-draggable-slug-folder').trigger('parti-draggable-slug-folder-item-wait');

            // 폴더의 경우 말단 폴더인지 확인합니다. 말단 폴더는 게시물만 포함됩니다.
            var $subcontainers = $item.find('> .js-draggable-slug-folder-container');
            if($subcontainers.length > 0) {
              if($item.parents('.js-draggable-slug-folder-container').length > 1) {
                $subcontainers.data('draggable-slug-folder-acceptable-type', 'post');
              } else {
                $subcontainers.data('draggable-slug-folder-acceptable-type', 'any');
              }
            }

            // 소팅
            var $last_dom;
            var $container = $item.closest('.js-draggable-slug-folder-container');

            $container.find('> .js-draggable-slug-folder-rows').each(function(index, elm) {
              var $elm = $(elm);
              if(!!$last_dom) {
                $elm.before($last_dom);
                $last_dom = $elm;
              } else {
                $elm.prependTo($container);
                $last_dom = $elm;
              }
            });
            $container.find('> .js-draggable-slug-folder-item').each(function(index, elm) {
              var $elm = $(elm);
              if(!!$last_dom) {
                $elm.before($last_dom);
                $last_dom = $elm;
              } else {
                $elm.prependTo($container);
                $last_dom = $elm;
              }
            });
            // 기본 로직 수행
            _super($item, container);

            // 서버에 저장
            if(container) {
              var data = container.el.parent().closest('.js-draggable-slug-folder-container').sortable('serialize').get();
              payload_json = JSON.stringify(data, null, ' ');
              autosave_payload($item.data('draggable-slug-folder-json-params'));
            } else {
              console.log('container blank!')
            }
          },
          serialize: function($parent, $children, parentIsContainer) {
            if(parentIsContainer) {
              return $children;
            }

            var result = $parent.data('draggable-slug-folder-json-params') || {};
            if($children[0]){
              result.children = $children;
            }
            return result;
          },
          isValidTarget: function ($item, container) {
            var container_type = container.el.data('draggable-slug-folder-acceptable-type');
            var valid_type = (container_type === 'any' || $item.data('draggable-slug-folder-item-type') == container_type);

            var container_depth = container.el.parents('.js-draggable-slug-folder-container').length;
            var current_depth = depth($item);
            return valid_type && (current_depth === 0 || (container_depth + current_depth <= max_depth));
          },
        });

        $base_elm .data('sortable-group', group);
        $(window).on('resize', on_resize);
        on_resize();
      }

      init_group();

      $base_elm.on('parti-draggable-slug-folder-item-destroy', function(e) {
        $(window).off('resize', on_resize);
        var group = $(this).data('sortable-group');
        if(group) {
          group.sortable('destroy');
          $(this).data('sortable-group', null);
        }
      });

      $base_elm.on('parti-draggable-slug-folder-item-wait', function(e) {
        var group = $(this).data('sortable-group');
        if(group) {
          group.sortable('disable');
          $('body').addClass('draggable-slug-folder-dropping');
        }
      });

      $base_elm.on('parti-draggable-slug-folder-item-save', function(e) {
        var data = $(this).sortable("serialize").get();
        payload_json = JSON.stringify(data, null, ' ');
        autosave_payload();
      });
    });
  })();

  // form dirty check
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

  $base.data('parti-prepare-arel', 'completed');
}

function parti_prepare_comment(comment_form_control_selector, nickname, text) {
  var $control = $(comment_form_control_selector);
  if ($control.length <= 0) {
    return;
  }
  $control.closest('.js-comment-form-wrapper').show();

  var adding = '';

  if ($.is_present(nickname)) {
    adding = '@' + nickname;
  }

  if ($.is_present(text)) {
    adding += ' ' + text;
  }

  var original_value = $control.val();

  if($.is_present(adding) && !$.is_blank(original_value)) {
    var escaped_adding = $.escape_regexp(adding);
    if(new RegExp('(^|\\s)' + escaped_adding + '($|\\s)').test(original_value)) {
      adding = '';
    }
  }

  if($.is_present(adding)) {
    var adding = adding + ' ';
  }
  $control.val('');
  $control.focus();
  $control.val(adding + original_value);

  autosize.update(document.querySelectorAll(comment_form_control_selector));

  $control.trigger('parti-need-to-validate');
}

$('[data-action="parti-clearable-search"]').each(function(i, elm) {
  if($.is_present($(elm).val())) {
    $(elm).addClear({
      showOnLoad: true,
      onClear: function(){
        $(elm).val('');
        $(elm).closest("form").submit();
      }
    });
  }
});

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

  // 글쓰기 - 파일업로드
  (function() {
    var formatBytes = function(bytes,decimals) {
       if(bytes == 0) return '0 Bytes';
       var k = 1000,
           dm = decimals + 1 || 3,
           sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
           i = Math.floor(Math.log(bytes) / Math.log(k));
       return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    function check_to_hide_or_show_add_link($form) {
      var count = $form.find('.js-post-editor-file_sources-wrapper .nested-fields:visible').length;
      if (count >= 20) {
        $form.find('.js-post-editor-file_sources-add-btn').hide();
      } else {
        $form.find('.js-post-editor-file_sources-add-btn').show();
      }

      $form.find('.js-post-editor-file_sources-add-btn .js-current-count').text(count);
    }

    function check_remotipart($form) {
      if($form.data('remote') !== true) {
        return;
      }

      var count = $form.find('.js-post-editor-file_sources-wrapper .nested-fields:visible').length;
      var $need_remotipart = $form.find("input[name='need_remotipart']");
      if ($need_remotipart.length <= 0) {
        $need_remotipart = $('<input type="hidden" name="need_remotipart" />');
        $form.append($need_remotipart);
      }

      if (count > 0) {
        $need_remotipart.val('true');
      } else {
        $need_remotipart.val('false');
      }
    }

    $('body').on('change', '.js-editor-file_source-attachment-input', function(e) {
      if (!(this.files && this.files[0])) {
        return;
      }

      var $target = $(e.currentTarget);
      var current_file = this.files[0];
      var current_input = $(this);
      var $form = $(this).closest('form');
      var object_name = $(this).closest('.form-group').data('object-name')
      var $form_group = $form.find(".js-editor-file_source-form-group[data-object-name='" + object_name + "']");
      var $all_form_groups = $form.find(".js-editor-file_source-form-group");

      if(parseInt($(this).data('rule-filesize')) < current_file.size) {
        UnobtrusiveFlash.showFlashMessage('10MB이하의 파일만 업로드 가능합니다', {type: 'error'})
        $form_group.remove();
      } else {
        if( typeof(URL.createObjectURL) === "function" && /^image/.test(current_file.type) ){
          $form_group.find('.js-upload-image img').attr('src', URL.createObjectURL(current_file));
          $form_group.find('.js-upload-image').removeClass('collapse');
          $form_group.css('display', 'inline-block');
          $form.find('.js-form-group-images').addClass('js-any');
          check_to_hide_or_show_add_link($form);
          check_remotipart($form);
        } else {
          $form_group.find('.js-upload-doc .name').text(current_file.name);
          $form_group.find('.js-upload-doc .size').text(formatBytes(current_file.size));
          $form_group.find('.js-upload-doc').removeClass('collapse');
          $form_group.css('display', 'block');
          $form.find('.js-form-group-files').addClass('js-any');
          $form_group.detach().appendTo($form.find('.js-form-group-files'));
        }
      }

      check_to_hide_or_show_add_link($form);
      check_remotipart($form);
    });

    $('body').on('parti-form-after-removing-attachment-input', 'form', function(e) {
      $form = $(e.currentTarget);
      check_to_hide_or_show_add_link($form);
      check_remotipart($form);
    });
  })();

  // 실제 메일인지 확인
  setTimeout(function(){
    $('#js-check-real-email').fadeIn();
  }, 2000);

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
      $icon = $('.js-show-all-pinned-post').find('.js-show-all-pinned-post-icon')
      if(visible) {
        $('.js-posts-pinned-and-behold').hide();
        $icon.removeClass(unfold_icon);
        $icon.addClass(fold_icon);
      } else {
        $('.js-posts-pinned-and-behold').show();
        $icon.removeClass(fold_icon);
        $icon.addClass(unfold_icon);
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
  });

  $('[data-action="parti-collapse"]').each(function(i, elm) {
    var parent = $(elm).data('parent');
    $(elm).on('click', function(e) {
      $(parent + ' .collapse').collapse('toggle');
      $(parent + ' [data-action="parti-collapse"]').toggleClass('collapsed');
    });
  });

  // 특정 영역을 클릭할 때
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

    var $__sidebar_scroll_container = $('.js-sidebar-scroll-container').first();

    // 사이드바에서 현재 선택된 영역까지 얼마나 스크롤 해야하는지 선택
    var current_scroll_to = function($current_group_issue) {
      var scroll_to = $__sidebar_scroll_container.scrollTop();
      if($current_group_issue && $current_group_issue.length > 0) {
        $current_group_issue.prevAll().each(function(index, elm){
          var $unfold = $(elm).find('.js-sidemenu-toggle-issues-unfold');
          if($unfold.length > 0) {
            scroll_to -= $unfold.outerHeight();
          }
        });
        return scroll_to;
      }

      return 0;
    }

    var scroll_sidebar_callback = function(e) {
      // 가급적 빨리 쿠키를 처리
      var scrollto_from_cookie = Cookies.get('sidebarScroll.' + location.host);
      if(scrollto_from_cookie) {
        Cookies.remove('sidebarScroll.' + location.host, { domain: __root_domain });
        sessionStorage.sidebarScroll = scrollto_from_cookie;
      }

      var $elm = $('.js-sidemenu-highlight-current-item').first();
      if($elm.length <= 0) {
        return;
      }

      // 사이드바 활성화 여부 판단
      if($elm.offset().top === 0 && $elm.offset().left === 0) {
        var scroll_sidebar_callback_on_slideopen = function(e) {
          scroll_sidebar_callback(e);
          $(document).off("parti-slide-open", scroll_sidebar_callback_on_slideopen);
        }
        $(document).off("parti-slide-open", scroll_sidebar_callback_on_slideopen);
        $(document).on("parti-slide-open", scroll_sidebar_callback_on_slideopen);
        return;
      }

      if(scrollto_from_cookie) {
        $__sidebar_scroll_container.scrollTop(scrollto_from_cookie);
        return;
      }

      if(sessionStorage.sidebarScroll) {
        $__sidebar_scroll_container.scrollTop(sessionStorage.sidebarScroll);
      }

      if(!$.viewport('belowthefold', $elm,  {threshold : -1 * $elm.outerHeight()})) {
        return;
      }

      var $current_group_issue = $elm.parents('.js-group-issues-line').first();
      $__sidebar_scroll_container.scrollTo($current_group_issue);

      if(!$.viewport('belowthefold', $elm,  {threshold : -1 * $elm.outerHeight()})) {
        return;
      }

      $__sidebar_scroll_container.scrollTo($elm, {
        offset: {
          top: (-1 * $__sidebar_scroll_container.innerHeight() + 2 * $elm.outerHeight() + $('#site-header').outerHeight())
        }
      });

      sessionStorage.sidebarScroll = $__sidebar_scroll_container.scrollTop();
    }
    $(document).on('parti-drawer-init-scroll', scroll_sidebar_callback);

    $(document).on('click', '[data-action="parti-issue-link"]', function(e) {
      $elm = $(e.currentTarget);

      var $current_group_issue = $elm.parents('.js-group-issues-line').first();
      if(!$current_group_issue || $current_group_issue.length < 0) {
        return;
      }

      var group_id = $current_group_issue.data('sidemenu-toggle-group-id');
      var group_subdomain = $current_group_issue.data('sidemenu-toggle-group-subdomain');
      if(group_id && group_subdomain) {
        Cookies.set('sidebarScroll.' + group_subdomain + '.' + __root_domain, current_scroll_to($current_group_issue), { domain: __root_domain });
      }

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

  (function() {
    var is_first_loaded = false

    var listen_waypoint = function($waypoint_element) {
      $waypoint_element.waypoint({
        handler: function(direction) {
          load_page_with_waypoint(this);
        },
        offset: "100%"
      });
    }

    var load_page = function($waypoint_element) {
      if($waypoint_element.length <= 0) {
        return;
      }
      if(!$waypoint_element.is(':visible')) {
        return;
      }

      var $container = $($waypoint_element.data('target'));
      if($container.data('is-last')) {
        return;
      }

      $('.js-page-waypoint-loading').show();

      $.ajax({
        url: $waypoint_element.data('url'),
        type: "get",
        data:{ last_stroked_at: $container.data('last-stroked-at') },
        context: $waypoint_element,
        success: function(xhr) {
          var $waypoint_element = this;
          listen_waypoint($waypoint_element);
        },
        complete: function(xhr) {
          $('.js-page-waypoint-loading').hide();
          is_first_loaded = true
        },
      });
    }

    var load_page_with_waypoint = function(waypoint) {
      var $waypoint_element = $(waypoint.element)
      waypoint.destroy();

      load_page($waypoint_element);
    };

    listen_waypoint($('.js-page-waypoint'));
    load_page($('.js-page-waypoint-onload'));
  })();

  $('[data-action="parti-select-interested-tag"]').each(function(index, elm){
    $(this).on('click',function (e){
      if($(this).hasClass('selected-tag')) {
        $(this).removeClass('selected-tag');
      } else {
        $(this).addClass('selected-tag');
      }

      if($('[data-action="parti-select-interested-tag"].selected-tag').length > 0) {
        $('.js-intro-select-parties-cog').addClass('collapse');
        $('.js-intro-select-parties-continue').removeClass('collapse');
      } else {
        $('.js-intro-select-parties-cog').removeClass('collapse');
        $('.js-intro-select-parties-continue').addClass('collapse');
      }
    });
  });

  $('.js-intro-select-parties-continue').each(function(index, elm){
    $(this).on('click',function (e){
      $(e.target).html('추천 중...');
      $(e.target).prop('disabled', true);
      $.ajax({
        url: '/parties/search_by_tags.js',
        type: "get",
        data:{
          selected_tags: $('.selected-tag').text().trim().split(/\s+/),
        },
        complete: function(xhr) {
          $('.parti-member-recommend--select-interest').hide();
          $('#header-before-select-tags').hide();
          $('#header-after-select-tags').removeClass('hide');
          $.scrollTo(0, 0);
        },
      });
      return false;

    });
  });

  $('[data-action="parti-confirm-merge"]').each(function(index, elm){
    $(this).on('click',function (e){
      var source = $($(this).data('source')).val()
      var target = $($(this).data('target')).val()
      return confirm( '----------------------------------------\n지워지는 채널와 위키: ' + source + '\n합해지는 채널: ' + target + '\n\n이대로 진행하시겠습니까? 이 행위는 되돌릴 수 없습니다.\n----------------------------------------')
    });
  });

  // history back
  $('.js-btn-history-back-in-mobile-app').on('click', function(e) {
    e.preventDefault();
    if(ufo.isApp()) {
      ufo.goBack();
    }
  });

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
      $('#js-main-panel').removeClass('sidebar-open-in-advance');
      $('.js-bottom-banner').trigger('parti-resize-bottom-banner');
    });
  })();

  // 위키 폴더 목록 클릭
  $('.js-folder-togglex').on('click', function(e) {
    var $elm = $(e.currentTarget);
    $elm.siblings('.js-folder-posts').slideToggle(100, function() {
      if($(this).is(':visible')) {
        $elm.find('.js-folder-togglex-icon').removeClass('fa-folder').addClass('fa-folder-open');
      } else {
        $elm.find('.js-folder-togglex-icon').removeClass('fa-folder-open').addClass('fa-folder');
      }
    });
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

  // close mobile editor
  $('.js-close-editor-in-mobile-app').on('click', function(e) {
    $('.js-btn-history-back-in-mobile-app').show();
    $('.js-btn-drawer').show();
    $('.js-close-editor-in-mobile-app').addClass('hidden');

    $('.js-post-editor-intro').show();
    $('.js-post-editor').hide();

    $('.js-invisible-on-mobile-editing').stop().slideDown();
    $(document).trigger('parti-ios-virtaul-keyboard-close-for-tinymce');

    $('body').removeClass('js-no-pull-to-refresh');

    // 가상키보드를 쓰는 환경이면
    if($('body').hasClass('virtual-keyboard')) {
      $('.js-navbar-header').trigger('parti-navbar-header-ease');
    }
  });

  // open editor
  (function() {
    var callback = function(e) {
      var href = $(e.target).closest('a').attr('href')
      if (href && href != "#") {
        return true;
      }

      e.preventDefault();
      var $elm = $(e.currentTarget);

      var $target = $('.js-post-editor');
      $target.show({ duration: 1, complete: function() {
        $elm.hide({ duration: 1, complete: function() {
          var focus_id = $elm.data('focus');
          $focus = $(focus_id);
          $focus.focus();
          Waypoint.refreshAll();
        }});
      }});

      // 가상키보드를 쓰는 환경이면
      if($('body').hasClass('virtual-keyboard')) {
        $('.js-invisible-on-mobile-editing').slideUp();
        $('.js-btn-history-back-in-mobile-app').hide();
        $('.js-close-editor-in-mobile-app').removeClass('hidden');
        $('.js-navbar-header').trigger('parti-navbar-header-fix');
      }

      $('body').addClass('js-no-pull-to-refresh');
    }

    $('.js-post-editor-intro').on('click', callback);
    $('.js-post-editor-intro').on('parti-post-editor-intro', callback);
  })();


  // ios에서 가상 키보드에 따른 사이트 헤더 조정
  if($('body').hasClass('virtual-keyboard') && $('body').hasClass('ios')) {
    (function() {
      $('#js-main-panel').append('<input type="text" id="js-virtaul-keyboard-faker">');
      var $fake_input = $('#js-virtaul-keyboard-faker').css('position', 'fixed').css('top', '0').css('height', '0').css('width', 0).css('opacity', '0');

      function eventHandler(e) {
        var nowWithKeyboard = (e.type == 'focusin');
        $('body').toggleClass('view-with-ios-virtual-keyboard', nowWithKeyboard);
      }

      function eventHandlerForTinymce(e) {
        var nowWithKeyboard = (e.type == 'parti-ios-virtaul-keyboard-open-for-tinymce');
        $('body').toggleClass('view-with-ios-virtual-keyboard', nowWithKeyboard);
        if (!nowWithKeyboard) {
          $fake_input.focus().blur();
        }
      }

      $(document).on('focus blur', '#js-main-panel select, #js-main-panel textarea, #js-main-panel input[type=text], #js-main-panel input[type=date], #js-main-panel input[type=password], #js-main-panel input[type=email], #js-main-panel input[type=number], #js-main-panel div[contenteditable=true]', eventHandler);
      $(document).on('parti-ios-virtaul-keyboard-open-for-tinymce parti-ios-virtaul-keyboard-close-for-tinymce', eventHandlerForTinymce);
    })();
  }

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

  // 채널 생성 폼에서 그룹 선택하기
  (function() {
    function change_subdomain(subdomain) {
      if(subdomain.length > 0) {
        subdomain = subdomain + ".";
      }
      $('.js-form-issue-subdomain').text(subdomain);
    }

    $(".js-form-issue-select-group").on('change', function(e) {
      var $selected_option = $(e.currentTarget).find('option:selected');
      if($selected_option.length > 0) {
        change_subdomain($selected_option.data('subdomain'));
      }
    });
    $(".js-issue-form-group-toggle").on('change', function(e) {
      $('.js-issue-form-group-toggle-target').toggle($(e.currentTarget).is(":checked"));
      if(!$(e.currentTarget).is(":checked")) {
        $(".js-form-issue-select-group").find('option').prop("selected", false);
        $(".js-form-issue-select-group").find('option.js-issue-form-group-toggle-default').prop("selected", true);
        change_subdomain('');
      }
    });
  })();

  // 게시물 폴더 선택
  $(document).on('hidden.bs.select', '.js-folder-selector .bootstrap-select.js-parti-bootstrap-select', function(e) {
    var $bs_select_control = $(e.currentTarget);
    var $select_control = $bs_select_control.find('select');
    var select_value = $select_control.val();
    if(select_value == "-1") {
      $('.js-new-folder').show();
    } else {
      $('.js-new-folder').hide();
    }
    if(select_value == "-2") {
      $('.js-update-folder').show();
    } else {
      $('.js-update-folder').hide();
    }
    $select_control.trigger('parti-need-to-validate');
  });

  // 댓글 파일 업로드 폼 보이기
  $(document).on('click', '.js-show-comment-file-source-form', function(e) {
    var $form = $(e.currentTarget).closest('form');
    $form.find('.js-file-source-form').show();
    $form.find('.js-post-editor-file_sources-add-btn > a').trigger('click');
  });

  // 내 홈 탭
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

  if(window.matchMedia("screen and (max-width: 768px)").matches) {
    // 액션시트
    $('.js-dropdown-xs-actionsheet').on('show.bs.dropdown', function(e) {
      $(this).find('.dropdown-menu').first().stop(true, true).slideDown(400);
    });

    $('.js-dropdown-xs-actionsheet').on('hide.bs.dropdown', function(e) {
      $(this).find('.dropdown-menu').first().stop(true, true).slideUp(200);
    });
  }

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

  // 폴더 컨텍스트 메뉴
  $.contextMenu({
    selector: '.js-folder-item.js-folder-item-managable',
    trigger: 'right',
    events: {
      show: function(options){
        $(this).trigger('parti-folder-item-force-active');
      },
    },
    build: function($trigger, e) {
      var options = {
        items: {}
      };

      rename_menu = {
        name: "이름 편집",
        callback: function(itemKey, opt, e){
          opt.$trigger.trigger('parti-folder-item-force-rename');
        },
      }

      if($trigger.data('folder-item-type') === 'folder') {
        options.items["add_post"] = {
          name: "게시물 작성",
          callback: _.throttle(function(itemKey, opt, e){
            $.ajax({
              url: opt.$trigger.data('add-post-url'),
              type: 'get',
              crossDomain: false,
              xhrFields: {
                withCredentials: true
              }
            });
          }, 1000),
        };
        options.items["add_wiki"] = {
          name: "위키 작성",
          callback: function(itemKey, opt, e){
            location.href = opt.$trigger.data('add-wiki-url');
          },
        };

        options.items["sp1"] = '--------';

        if($trigger.data('folder-item-acceptable-type') === 'any' ||
          $trigger.data('folder-item-acceptable-type') === 'folder') {
          options.items["add_subfolder"] = {
            name: "하위 폴더 생성",
            callback: _.throttle(function(itemKey, opt, e){
              $.ajax({
                url: opt.$trigger.data('add-folder-url'),
                type: 'get',
                crossDomain: false,
                xhrFields: {
                  withCredentials: true
                }
              });
            }, 1000),
          };
        }

        options.items["remove"] = {
          name: "폴더 삭제",
          callback: _.throttle(function(itemKey, opt, e){
            var run = function() {
              $.ajax({
                url: opt.$trigger.data('remove-folder-url'),
                type: 'delete',
                crossDomain: false,
                xhrFields: {
                  withCredentials: true
                }
              });
            }

            if(opt.$trigger.parent('.js-folder-rows').find('.js-folder-children .js-folder-item').length > 0) {
              if(confirm('하위 폴더도 모두 지워집니다. 삭제되는 모든 폴더의 게시물은 폴더 정보가 제거됩니다. 단, 게시물은 삭제되지 않습니다. \n이 동작은 되돌릴 수 없습니다. 계속하시겠습니까?')) {
                run();
              }
            } else {
              run();
            }

          }, 1000),
        }

        options.items["sp2"] = '--------';
        options.items["rename"] = rename_menu;
      }

      if($trigger.data('folder-item-type') === 'post') {
        options.items["rename"] = rename_menu;
        options.items["eject"] = {
          name: "이 게시물을 폴더에서 제거",
          callback: _.throttle(function(itemKey, opt, e){
            $.ajax({
              url: opt.$trigger.data('detach-post-url'),
              type: 'delete',
              crossDomain: false,
              xhrFields: {
                withCredentials: true
              }
            });
          }, 1000),
        }
      }
      return options;
    }
  });
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
});

var parti_show_modal$ = function($partial) {
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').removeClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').removeClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').addClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').addClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').html($partial);
  $('#js-modal-placeholder > .modal').modal("show");
}

var parti_show_modal_sm$ = function($partial) {
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').removeClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').removeClass('modal-dialog-md');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').addClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-loading-dialog').addClass('modal-dialog-sm');
  $('#js-modal-placeholder .js-modal-placeholder-action-dialog').html($partial);
  $('#js-modal-placeholder > .modal').modal("show");
}
