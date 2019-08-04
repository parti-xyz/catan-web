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

// form validation by extern
$.validator.addMethod("extern", function(value, element) {
  return $(element).data('rule-extern-value') === 'valid';
}, function(params, element) {
  return $(element).data('rule-extern-error-message');
});

var __parti_prepare_form_validator = function($base) {
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

