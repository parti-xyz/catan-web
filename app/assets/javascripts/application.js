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
//= require autoresize
//= require jquery.validate
//= require additional-methods
//= require messages_ko
//= require kakao
//= require jquery.history
//= require jquery.waypoints
//= require jquery.dotdotdot
//= require jquery.webui-popover
//= require bootstrap-add-clear
//= require diacritics
//= require bootstrap-dropdown-filter
//= require bootstrap-select
//= require bootstrap-select/defaults-ko_KR.js
//= require jquery.viewport
//= require cocoon
//= require focus-element-overlay
//= require clipboard
//= require Sortable
//= require lightbox
//= require webp-check
//= require slick
//= require tinymce-jquery
//= require Chart.bundle
//= require chartkick
//= require mobile_app
//= require slideout

lightbox.option({
  'albumLabel': '이미지 %1 / %2',
  'resizeDuration': 200,
  'showImageNumberLabel': true,
  'imageFadeDuration': 400,
  'alwaysShowNavOnTouchDevices': true,
  fitImagesInViewport: true,
  wrapAround: false,
  maxHeight: 500,
  maxWidth: 500
})

$('.slick-slider').slick({
  slidesToShow: 5,
  slidesToScroll: 5,
  nextArrow: '<span class="slick-custom-next"><span class="fa-stack"><i class="fa fa-circle fa-stack-1x fa-inverse"></i><i class="fa fa-chevron-circle-right fa-stack-1x"></i></span></span>',
  prevArrow: '<span class="slick-custom-prev"><span class="fa-stack"><i class="fa fa-circle fa-stack-1x fa-inverse"></i><i class="fa fa-chevron-circle-left fa-stack-1x"></i></span></span>',
  responsive: [
    {
      breakpoint: 960,
      settings: {
        slidesToShow: 3,
        slidesToScroll: 3
      }
    },
    {
      breakpoint: 480,
      settings: {
        slidesToShow: 2,
        slidesToScroll: 1
      }
    }
  ]
});

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

$.fn.visible = function() {
    return this.css('visibility', 'visible');
};

$.fn.invisible = function() {
    return this.css('visibility', 'hidden');
};

$.fn.visibilityToggle = function() {
    return this.css('visibility', function(i, visibility) {
        return (visibility == 'visible') ? 'hidden' : 'visible';
    });
};

// fucusable
var parti_post_editor_spotlight = function(e) {
  var focusableOptions = { fadeDuration: 200, hideOnClick: true, hideOnESC: true, findOnResize: true }
  if(!$('[data-action="parti-post-editor-spotlight"]').length) {
    return;
  }
  if(!Focusable.getActiveElement()) {
    Focusable.setFocus($('[data-action="parti-post-editor-spotlight"]'), focusableOptions);
  } else {
    setTimeout(function() {
      Focusable.refresh();
    }, 10);
  }
}
$(document).on('parti-post-editor-spotlight', parti_post_editor_spotlight);

// unobtrusive_flash
UnobtrusiveFlash.flashOptions['timeout'] = 5000;

// Kakao Key
Kakao.init('6cd2725534444560cb5fe8c77b020bd6');

// form validation by extern
$.validator.addMethod("extern", function(value, element) {
  return this.optional(element) || $(element).data('rule-extern-value');
}, "");

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
    $submit.prop('disabled', true);

    $form.validate({
      ignore: ':hidden:not(.validate)',
      errorPlacement: function(error, element) {
        return true;
      }
    });

    if($form.valid()) {
      $submit.prop('disabled', false);
    }

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

    $elm.on('parti-need-to-validate', function(e) {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });

    $elm.find('.js-tinymce').on('change', function() {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });
  });
}

var parti_prepare = function($base) {
  if($base.data('parti-prepare-arel') == 'completed') {
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

  $.parti_apply($base, '[data-action="parti-popover"]', function(elm) {
    var options = {};
    var style = $(elm).data('style');
    if(style) {
      options['style'] = style;
    }

    var backdrop = $(elm).data('backdrop');
    if(backdrop) {
      options['backdrop'] = backdrop;
    }

    $(elm).webuiPopover(options);
  });

  // show
  $.parti_apply($base, '[data-action="parti-show"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);

      var $target = $($elm.data('show-target'));
      $target.show({ duration: 1, complete: function() {
        if($elm.data('self-hide')) {
          $elm.hide({ duration: 1, complete: function() {
            if($elm.data('spotlight-post-editor')) {
              $(document).trigger('parti-post-editor-spotlight');
            }
            var focus_id = $elm.data('focus');
            $focus = $(focus_id);
            $focus.focus();
          }});
        }
      }});
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
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);
      var $target = $($elm.data('focus-target'));
      $target.focus();
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
    if($(elm).data('in-post-modal')) {
      $(elm).on('focus', function(e) {
        $(elm).height('120');
      });
    } else {
      autosize($(elm));
    }
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

  //new comments count
  $.parti_apply($base, '[data-action="parti-polling"]', function(elm) {
    var $elm = $(elm);
    var polling_url = $(elm).data("polling-url");
    var polling_interval = $(elm).data("polling-interval");
    var count = 0;
    var update_new_comments = function() {
      if(count > 20) { return; }
      count += 1;
      $.getScript(polling_url);
      setTimeout(update_new_comments, polling_interval);
    }
    setTimeout(update_new_comments, polling_interval);
  });

  // modal tooltip
  $.parti_apply($base, '[data-toggle="tooltip"]', function(elm) {
    $(elm).tooltip();
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

  $.parti_apply($base, '[data-action="parti-show-more"]', function(elm) {
    $(elm).on('click',function (e){
      var $post = $($(this).data('more-wrapper'));
      $post.find('.original-body').show();
      $post.find('.truncated-body').hide();
    });
  });

  $base.data('parti-prepare-arel', 'completed');
}

//parti-post-modal
var parti_prepare_post_modal = function($base) {
  $.parti_apply($base, '[data-action="parti-filter-parties"]', function(elm) {
    var $elm = $(elm);
    $elm.on('click', function(e) {
      var search_form = $(this).data('search-form');
      var sort = $(this).data('search-sort');
      var category = $(this).data('search-category');
      var $elm = $(this);

      $(search_form).find("input[name='sort']").val(sort);
      $(search_form).find("input[name='category']").val(category);
      $(search_form).submit();
      return false;
    });
  });
};

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

var parti_partial$ = function($partial) {
  parti_prepare_post_modal($partial);
  parti_prepare($partial);

  return $partial;
}

var parti_ellipsis = function($partial) {
  $.parti_apply($partial, '[data-action="parti-ellipsis"]', function(elm) {
    $(elm).dotdotdot();
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

  // 빠띠 사이드바 hover 할때 가입 버튼 보이기
  $('.js-issue-line-hover').on('mouseenter', function(elm) {
    $(this).find('.js-join-sign').hide();
    $(this).find('.js-join-button').show();
  });
  $('.js-issue-line-hover').on('mouseleave', function(elm) {
    $(this).find('.js-join-button').hide();
    $(this).find('.js-join-sign').show();
  });

  $('.js-post-wiki-btn').on('click', function(e) {
    Focusable.hide();
    return true;
  });
  (function() {
    if($('#js-form-group-images').length > 0) {
      Sortable.create($('#js-form-group-images')[0]);
    }
    if($('#js-form-group-files').length > 0) {
      Sortable.create($('#js-form-group-files')[0]);
    }
    var formatBytes = function(bytes,decimals) {
       if(bytes == 0) return '0 Bytes';
       var k = 1000,
           dm = decimals + 1 || 3,
           sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
           i = Math.floor(Math.log(bytes) / Math.log(k));
       return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    function check_to_hide_or_show_add_link() {
      var count = $('#js-post-editor-file_sources-wrapper .nested-fields:visible').length;
      if (count >= 20) {
        $('#js-post-editor-file_sources-add-btn').hide();
      } else {
        $('#js-post-editor-file_sources-add-btn').show();
      }

      $('#js-post-editor-file_sources-add-btn .js-current-count').text(count);
    }

    $('body').on('change', '.js-editor-file_source-attachment-input', function(e) {
      if (!(this.files && this.files[0])) {
        return;
      }

      var current_file = this.files[0];
      var current_input = $(this);
      var object_name = $(this).closest('.form-group').data('object-name')
      var $form_group = $(".js-editor-file_source-form-group[data-object-name='" + object_name + "']");
      var $all_form_groups = $(".js-editor-file_source-form-group");

      if(parseInt($(this).data('rule-filesize')) < current_file.size) {
        UnobtrusiveFlash.showFlashMessage('10MB이하의 파일만 업로드 가능합니다', {type: 'error'})
        $form_group.remove();
      } else {
        if( typeof(URL.createObjectURL) === "function" && /^image/.test(current_file.type) ){
          // var reader = new FileReader();
          // reader.onload = function (e) {
          //   $form_group.find('.js-upload-image img').attr('src', e.target.result);
          //   $form_group.find('.js-upload-image').removeClass('collapse');
          //   $form_group.css('display', 'inline-block');
          //   $('#js-form-group-images').addClass('js-any');
          //   $(document).trigger('parti-post-editor-spotlight');
          //   check_to_hide_or_show_add_link();
          // }
          // reader.readAsDataURL(current_file);
          $form_group.find('.js-upload-image img').attr('src', URL.createObjectURL(current_file));
          $form_group.find('.js-upload-image').removeClass('collapse');
          $form_group.css('display', 'inline-block');
          $('#js-form-group-images').addClass('js-any');
          $(document).trigger('parti-post-editor-spotlight');
          check_to_hide_or_show_add_link();
        } else {
          $form_group.find('.js-upload-doc .name').text(current_file.name);
          $form_group.find('.js-upload-doc .size').text(formatBytes(current_file.size));
          $form_group.find('.js-upload-doc').removeClass('collapse');
          $form_group.css('display', 'block');
          $('#js-form-group-files').addClass('js-any');
          $(document).trigger('parti-post-editor-spotlight');
          $form_group.detach().appendTo('#js-form-group-files');
        }
      }

      check_to_hide_or_show_add_link();
    });

    $('#js-post-editor-file_sources-wrapper').on('cocoon:after-insert', function(e, item) {
      item.find("input[type='file']").trigger('click');
    });
    $('#js-post-editor-file_sources-wrapper').on('cocoon:after-remove', function(e, item) {
      var has_image = false;
      $("#js-form-group-images input[type='file']").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_image = true; }
      });
      $("#js-form-group-images input.js-id").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_image = true; }
      });

      if(!has_image) {
        $('#js-form-group-images').removeClass('js-any');
      }

      var has_file = false;
      $("#js-form-group-files input[type='file']").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_file = true; }
      });
      $("#js-form-group-files input.js-id").each(function(index, elm) {
        if($.is_present($(elm).val())) { has_file = true; }
      });

      if(!has_file) {
        $('#js-form-group-files').removeClass('js-any');
      }

      check_to_hide_or_show_add_link();
    });
  })();

  // 실제 메일인지 확인
  setTimeout(function(){
    $('#js-check-real-email').fadeIn();
  }, 2000);

  // 알림드롭다운
  $('#js-notification').on('show.bs.dropdown', function(e) {
    var $this = $(this);
    $.ajax({
      url: $this.data('url'),
      type: "get"
    });
  });

  $('.js-show-all-pinned-post').on('click', function(e) {
    $('.js-posts-pinned-and-read').show();
    $('.js-show-all-pinned-post-wrapper').hide();
  });

  $('#site-header').on('show.bs.collapse','.collapse', function() {
      $('#site-header').find('.collapse.in').collapse('hide');
  });

  $('.parti-editor-selectpicker').selectpicker('render');
  $('.parti-editor-selectpicker').on('changed.bs.select', function(e) {
    var select_value = $(this).val();
    var $input_elm = $('form.form-widget input[name*="[issue_id]"]');

    $input_elm.val(select_value);
    $input_elm.trigger('parti-need-to-validate');
  });
  $('.parti-editor-selectpicker').on('loaded.bs.select', function(e) {
    $(this).show();
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

  $(document).on('click', '[data-action="parti-link"]', function(e) {
    var href = $(e.target).closest('a').attr('href')
    if (href && href != "#") {
      return true;
    }

    var $no_parti_link = $(e.target).closest('[data-no-parti-link="no"]')
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

    if($.is_present($(this).data('link-target'))) {
      window.open(url, $(this).data('link-target'));
    } else if (e.shiftKey || e.ctrlKey || e.metaKey) {
      window.open(url, '_blank');
    } else {
      window.location.href  = url;
    }
  });

  $(document).on('click', '.js-download', function(e) {
    var href = $(e.target).closest('a').attr('href')
    if (href && href != "#") {
      return true;
    }

    var $no_parti_link = $(e.target).closest('[data-no-parti-link="no"]')
    if ($no_parti_link.length) {
      return true;
    }

    e.preventDefault();
    var url = $(e.currentTarget).data("url");
    var post_id = $(e.currentTarget).data("post-id");
    var file_source_id = $(e.currentTarget).data("file-source-id");
    var file_name = $(e.currentTarget).data("file-name");

    if(ufo.isApp()) {
      ufo.post("download", { post: post_id, file: file_source_id, name: file_name });
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
      var $container = $($waypoint_element.data('target'));
      if($container.data('is-last')) {
        return;
      }

      $('.js-page-waypoint-loading').show();

      $.ajax({
        url: $waypoint_element.data('url'),
        type: "get",
        data:{ last_id: $container.data('last-id') },
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

  $('[data-action="parti-home-slide"] a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var hash = $(e.target).attr('href');
    var $containers = $($(e.target).data('slide-target'));
    var $all_tab_panes = $($containers.find('.tab-pane'))
    var $target_tab_panes = $($containers.find('.tab-pane' + hash))
    $all_tab_panes.removeClass('active');
    $target_tab_panes.addClass('active');
  })

  if ( $('#wikis .body .wiki_content a').length ){
    $('#wikis .body .wiki_content a').attr('target', '_blank');
  }

  $('[data-action="parti-post-select-subform"]').each(function(index,elm){
    var hidden_target = $(elm).data('hidden-target');
    var reference_field = $(elm).data('reference-field');
    var has_poll = $(elm).data('has-poll');
    var has_survey = $(elm).data('has-survey');
    var file_input = $(elm).data('file-input');
    $(this).on('click',function (e){
      e.preventDefault();
      $(hidden_target).hide();
      if($(reference_field).hasClass('hidden')){
        $(reference_field).removeClass('hidden');
      }
      if($(this).hasClass('post-poll-btn')){
        $(has_poll).val(true);
      } else if($(this).hasClass('post-survey-btn')){
        $(has_survey).val(true);
      } else if($(this).hasClass('post-file-btn')) {
        if($.is_blank($(file_input).val())) {
          $(file_input).trigger('click');
        }
      }
      $(elm).closest('[data-action="parti-form-validation"]').trigger('parti-need-to-validate');
    })
  });

  $('[data-action="parti-post-cancel-subform"]').each(function(index,elm){
    var reference_field = $(elm).data('reference-field');
    var show_target = $(elm).data('show-target');
    var has_poll = $(elm).data('has-poll');
    var has_survey = $(elm).data('has-survey');
    $(this).on('click',function(e){
      e.preventDefault();

      $(reference_field).addClass('hidden');
      $(show_target).show();
      $(document).trigger('parti-post-editor-spotlight');
      $(has_poll).val(false);
      $(has_survey).val(false);

      $(elm).closest('[data-action="parti-form-validation"]').trigger('parti-need-to-validate');

      return false;
    });
  });

  $('[data-action="parti-select-interested-tag"]').each(function(index, elm){
    $(this).on('click',function (e){
      if($(this).hasClass('selected-tag')) {
        $(this).removeClass('selected-tag');
      } else {
        $(this).addClass('selected-tag');
      }
    });
  });

  $('[data-action="parti-select-parties"]').each(function(index, elm){
    $(this).on('click',function (e){
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
        },
      });
      return false;

    });
  });

  $('[data-action="parti-confirm-merge"]').each(function(index, elm){
    $(this).on('click',function (e){
      var source = $($(this).data('source')).val()
      var target = $($(this).data('target')).val()
      return confirm( '----------------------------------------\n지워지는 빠띠와 위키: ' + source + '\n합해지는 빠띠: ' + target + '\n\n이대로 진행하시겠습니까? 이 행위는 되돌릴 수 없습니다.\n----------------------------------------')
    });
  });

  $('[data-action="parti-post-editor-spotlight"]').each(function(index, elm){
    $(elm).on('click',function (e){
      $(document).trigger('parti-post-editor-spotlight');
    });
    $(elm).on('focusable.focused', function(e) {
      $('body').addClass('editor-spotlight');
    });
    $(elm).on('focusable.hidden', function(e) {
      $('#site-header > nav').addClass('navbar-fixed-top');
      $('body').removeClass('editor-spotlight');
    });
  });

  // drawer
  (function() {
    if($('#js-drawer').length <= 0 && $('#js-main').length <= 0) {
      return;
    }
    var slideout = new Slideout({
      'panel': $('#js-main')[0],
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

  // editor
  (function() {
    var setPlaceholder = function(editor, placeholder) {
      editor.setContent("<p id='js-tinymce-placeholder' class='tinymce-placeholder'>" + placeholder + "</p>");
    };

    var removePlaceholder = function(editor, placeholder) {
      $placeholder = $("#js-tinymce-placeholder");
      if($placeholder.length) {
        $placeholder.remove();
        editor.setContent("<p></p>");
        return true;
      }

      return false
    };

    //plugins: 'image media link paste contextmenu textpattern autolink',
    var settings = {
      default: {
        plugins: 'link paste autolink lists advlist',
        insert_toolbar: '',
        selection_toolbar: 'bold italic strikethrough | quicklink blockquote | bullist numlist | outdent indent',
      },
      wiki: {
        plugins: 'image media link paste autolink uploadimage lists advlist',
        insert_toolbar: '',
        selection_toolbar: 'bold italic strikethrough | quicklink h1 h2 h3 blockquote | bullist numlist | outdent indent | uploadimage',
      },
    };

    $.each($('.js-tinymce'), function(i, elm){
      var setting_name = $(elm).data('tinymce-setting');
      var setting = settings.default;
      if(setting_name) {
        setting = settings[setting_name];
      }
      var placeholder = $(elm).data('placeholder');

      $(elm).tinymce({
        theme: 'inlite',
        inline: true,
        language: 'ko_KR',
        plugins: setting.plugins,
        insert_toolbar: setting.insert_toolbar,
        selection_toolbar: setting.selection_toolbar,
        paste_data_images: true,
        document_base_url: 'https://parti.xyz/',
        link_context_toolbar: true,
        relative_urls: false,
        remove_script_host : false,
        hidden_input: false,
        uploadimage_default_img_class: 'tinymce-content-image',
        setup: function (editor) {
          if(placeholder) {
            editor.on('init', function(){
              setPlaceholder(editor, placeholder);
            });
            editor.on('blur', function (e) {
              var $input_elm = $(':input[name="' + editor.id + '"]');
              if($input_elm.val() == "") {
                setPlaceholder(editor, placeholder);
              }
            });
            editor.on('focus', function (e) {
              if(removePlaceholder(editor)) {
                editor.execCommand('mceFocus', false);
                $(document).trigger('parti-post-editor-spotlight');
              }
            });
            editor.on('KeyDown', function (e) {
              removePlaceholder(editor);
            });
          }
        },
        init_instance_callback: function (editor) {
          editor.on('change', function (e) {
            tinymce.triggerSave();
            var $input_elm = $(':input[name="' + editor.id + '"]');
            $input_elm.trigger('parti-need-to-validate');
            $(document).trigger('parti-post-editor-spotlight');
          });
        }
      });
    });
  })();

});
