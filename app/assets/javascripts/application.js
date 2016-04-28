//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require bootstrap-typeahead
//= require masonry.pkgd
//= require bootstrap.offcanvas
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

// blank
$.is_blank = function (obj) {
  if (!obj || $.trim(obj) === "") return true;
  if (obj.length && obj.length > 0) return false;

  for (var prop in obj) if (obj[prop]) return false;
  return true;
}

$.is_present = function(obj) {
  return ! $.is_blank(obj);
}

$.parse$ = function(str) {
  return $($.parseHTML('<div>' + $.trim(str) + '</div>'));
}

$.prevent_click_exclude_parti = function(e) {
  e.preventDefault();
  $(e.currentTarget).trigger('parti-click');
}
// unobtrusive_flash
UnobtrusiveFlash.flashOptions['timeout'] = 3000;

// Kakao Key
Kakao.init('6cd2725534444560cb5fe8c77b020bd6');

// form validation by extern
$.validator.addMethod("extern", function(value, element) {
  return this.optional(element) || $(element).data('rule-extern-value');
}, "");

var parti_prepare = function($base) {
  if($base.data('parti-prepare-arel') == 'completed') {
    return;
  }

  var parti_apply = function(query, callback) {
    $.each($base.find(query), function(i, elm){
      callback(elm);
    });
  }

  // typeahead
  parti_apply('[data-provider="parti-issue-typeahead"]', function(elm) {
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

  //masonry
  parti_apply('.masonry-container', function(elm) {
    $(elm).masonry({
      itemSelector: '.card'
    });
  });

  //switch
  parti_apply('[data-action="parti-switch"]', function(elm) {
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
  parti_apply('[data-action="parti-show"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);
      var $target = $($elm.data('show-target'));
      $target.show();
      var focus_id = $elm.data('focus');
      $focus = $(focus_id);
      $focus.focus();
    });
  });

  //hide
  parti_apply('[data-action="parti-hide"]', function(elm) {
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
  parti_apply('[data-action="parti-focus"]', function(elm) {
    $(elm).on('click', function(e) {
      var $elm = $(e.currentTarget);
      var $target = $($elm.data('focus-target'));
      setTimeout(function(){
        $target.focus();
      },10);
    });
  });

  //share
  parti_apply('[data-action="parti-share"]', function(elm) {
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
      Kakao.Story.createShareButton({
        container: elm,
        url: url,
        text: text
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
  parti_apply('[data-ride="parti-carousel"]', function(elm) {
    var $elm = $(elm);
    var margin = $elm.data('carousel-magin');
    if(!margin) {
      margin = 0;
    }
    $elm.owlCarousel({
      loop: $elm.children().length > 1,
      nav: $elm.children().length > 1,
      margin: margin,
      navText: [
        '<i class="fa fa-arrow-left">',
        '<i class="fa fa-arrow-right">',
      ],
      dots: false,
      responsive:{
          0:{
              items:1
          },
          1000:{
              items:2
          }
      }
    });
    var next = $elm.data('carousel-next');
    var prev = $elm.data('carousel-prev');
    $(next).click(function(){
      $elm.trigger('owl.next');
    });
    $(prev).click(function(){
      $elm.trigger('owl.prev');
    });
  });

  // login overlay
  parti_apply('[data-toggle="parti-login-overlay"]', function(elm) {
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
  parti_apply('[data-dismiss="parti-login-overlay"]', function(elm) {
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
  parti_apply('[data-action="parti-form-submit"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $elm = $(e.currentTarget);
      var $form = $($elm.data('form-target'));
      var url = $elm.data('form-url');
      $form.attr('action', url);
      $form.submit();
    });
  });

  // form set value
  parti_apply('[data-action="parti-form-set-vaule"]', function(elm) {
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
  parti_apply('[data-ride="parti-autoresize"]', function(elm) {
    autosize($(elm));
  });

  // form validator
  parti_apply('[data-action="parti-form-validation"]', function(elm) {
    var $elm = $(elm);
    var $form = $(elm);
    var $submit = $($elm.data("submit-form-control"));
    $submit.prop('disabled', true);

    $form.validate({
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

    $elm.find(':input').on('parti-need-to-validate', function(e) {
      if($form.valid()) {
        $submit.prop('disabled', false);
      } else {
        $submit.prop('disabled', true);
      }
    });
  });

  // mention
  parti_apply('[data-action="parti-mention"]', function(elm) {
    $(elm).on('click', function(e) {
      $.prevent_click_exclude_parti(e);
      var $target = $(e.currentTarget);
      var $control = $($target.data('mention-form-control'));
      var nickname = $target.data('mention-nickname');
      var value = $control.val();
      $control.val('@' + nickname + ' ' + value);
      $control.focus();
    });
  });

  // cancel form on blur
  parti_apply('[data-action="parti-cancel-form-on-blur"]', function(elm) {
    var $elm = $(elm);

    var close_form = function(e) {
      if($elm.has(e.target).length == 0) {
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
  parti_apply('#post-modal-permalink', function(elm) {
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
  parti_apply('[data-action="parti-polling"]', function(elm) {
    var $elm = $(elm);
    var polling_url = $(elm).data("polling-url");
    var polling_interval = $(elm).data("polling-interval");

    var update_new_comments = function() {
      $.getScript(polling_url);
      setTimeout(update_new_comments, polling_interval);
    }
    setTimeout(update_new_comments, polling_interval);
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
  var container = target + ' .post__partial-content';

  var nickname = '';
  var mention_form_control = '';
  var is_mention = false;

  $target.data('parti-pjax-back-trigger', 'off');
  $target.on('pjax:success', function(e, data, status, xhr, options) {
    parti_prepare($(container).children());
    $target.data('parti-pjax-back-trigger', 'on');

    var nickname = $target.data('mention-nickname');
    var mention_form_control = $target.data('mention-form-control');

    is_mention = $.is_present(mention_form_control) && $.is_present(nickname);

    if (is_mention) {
      var control = $target.find(mention_form_control);
      var value = $(control).val();
      var at_nickname = '@' + nickname;
      if ($.is_blank(value) || value.indexOf(at_nickname) == -1) {
        $(control).val(at_nickname + ' ' + value);
      }
    }
    $target.modal('show');
    if (is_mention) {
      $target.on('shown.bs.modal', function (e) {
        $(control).focus();
      });
    }
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
      $target.data('mention-nickname', nickname);
      $target.data('mention-form-control', mention_form_control);
      $.pjax({url: url, container: container, scrollTo: false, timeout: 5000});
      return false;
    });
  });

  $base.data('parti-prepare-post-modal-arel', 'completed');
};

//parti-post-modal
var parti_partial = function(partial) {
  var $partial = $.parse$(partial)
  parti_prepare_post_modal($partial);
  parti_prepare($partial);

  return $partial;
}

$(function(){
  parti_prepare($('body'));
  parti_prepare_post_modal($('body'));

  $(document).ajaxError(function (e, xhr, settings) {
    if(xhr.status == 500) {
      UnobtrusiveFlash.showFlashMessage('뭔가 잘못되었습니다. 곧 고치겠습니다.', {type: 'error'})
    } else if(xhr.status == 404) {
      UnobtrusiveFlash.showFlashMessage('어머나! 누가 지웠네요. 페이지를 새로 고쳐보세요.', {type: 'notice'})
    }
  });
});

// modal tooltip
$(function () {
  $('[data-toggle="tooltip"]').tooltip()
});
