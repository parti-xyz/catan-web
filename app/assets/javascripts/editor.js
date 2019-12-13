var __parti_prepare_editor = function($base) {
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

  // 게시글 쓸때 채널 선택하기
  $.parti_apply($base, '.js-parti-editor-selector', function(elm) {
    var $elm = $(elm);

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

  // tinymce
  // editor
  (function() {
    var fix_list_dummy_uid = "___uid___" + Math.random().toString(36).substr(2, 16);
    var is_list_dom = function(dom) {
      if(!dom) return false;
      if(!dom.nodeName) return false;

      return ('ul' === dom.nodeName.toLowerCase() || 'ol' === dom.nodeName.toLowerCase());
    }

    var is_list_item_dom = function(dom) {
      if(!dom) return false;
      if(!dom.nodeName) return false;

      return ('li' === dom.nodeName.toLowerCase());
    }

    var is_text_dom = function(dom) {
      if(!dom) return false;
      return dom.nodeType === 3;
    }

    var is_ignore_dom = function(dom) {
      if(!dom) return true;
      if(is_text_dom(dom) && $(dom).text().trim().length <= 0) {
        return true;
      }
    }

    var list_fix = function(node) {
      try {
        var $node = $(node);
        var $list = $node.find('ul,ol');
        $.each($list.contents(), function(index, item) {
          if(is_ignore_dom(item)) {
            return;
          }

          if(!item.nodeName || item.nodeName.toLowerCase() != 'li') {
            var $item = $(item);
            $item.wrap('<li>');
          }
        });

        var $relist = $node.find('ul,ol');
        $.each($relist.contents(), function(index, list_item) {
          if(is_ignore_dom(list_item)) {
            return;
          }

          var $list_item = $(list_item);
          var previous_subitem = null;
          $.each($list_item.contents(), function(index, current_subitem) {
            if(is_ignore_dom(current_subitem)) {
              return;
            }

            var $current_subitem = $(current_subitem);
            if(index === 0 && (is_list_dom(current_subitem) || is_list_item_dom(current_subitem))) {
              var $new_previous_subitem = $('<span class="' + fix_list_dummy_uid + '">&nbsp;</span>');
              $new_previous_subitem.insertBefore($current_subitem);
              previous_subitem = $new_previous_subitem[0];
            }

            if(is_list_dom(current_subitem)) {
              if(is_list_dom(previous_subitem)) {
                $(previous_subitem).append($(current_subitem).contents());
                $(current_subitem).remove();
                return;
              }
              previous_subitem = current_subitem;
              return;
            } else if(is_list_item_dom(current_subitem)) {
              var $new_previous_subitem = $('<ul></ul>');
              $(current_subitem).wrap($new_previous_subitem);
              previous_subitem = $new_previous_subitem[0];
              return;
            } else {
              if(is_list_dom(previous_subitem)) {
                $(current_subitem).appendTo($(previous_subitem)).wrap('<li>');
                return;
              }
              previous_subitem = current_subitem;
              return;
            }
          });
        });

        var $dummy_span = $node.find('.' + fix_list_dummy_uid);
        $.each($dummy_span, function(index, dummy_span) {
          var $dummy_li = $(dummy_span).parent();
          var $previous_li = $dummy_li.prev();
          if(is_list_item_dom($previous_li[0])) {
            $dummy_li.remove();
            $previous_li.append($dummy_li.contents());
            $dummy_li.remove();
          }
        });

        $node.find('p').addClass('d277bc4d-a73e-4b2e-94ed-bbe7c1934b74').after('<p class="d277bc4d-a73e-4b2e-94ed-bbe7c1934b74"><br data-mce-bogus="1"></p>');
      } catch(ignore) {
        console.log(ignore);
      }
    }
    //plugins: 'image media link paste contextmenu textpattern autolink quickbars',
    var settings = {
      default: {
        plugins: 'stickytoolbar link paste autolink autosave lists autoresize hot-style table',
        toolbar: 'bold italic strikethrough | link blockquote | style-h1 style-h2 style-h3 | bullist numlist outdent indent',
        // toolbar: false,
        quickbars_insert_toolbar: false,
        quickbars_selection_toolbar: false, //'bold italic | blockquote quicklink',
        forced_root_block: 'p',
        min_height: 160,
      },
      wiki: {
        plugins: 'stickytoolbar link paste autolink autosave lists autoresize hot-style table',
        toolbar: 'bold italic strikethrough | link blockquote | style-h1 style-h2 style-h3 |  bullist numlist outdent indent | table',
        quickbars_insert_toolbar: false,
        quickbars_selection_toolbar: false,
        forced_root_block: 'p',
        min_height: 300,
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
        cache_suffix: '?v=5.0.12.0.2',
        language: 'ko_KR',
        plugins: setting.plugins,
        menubar: false,
        min_height: setting.min_height,
        forced_root_block : setting.forced_root_block,
        forced_root_block_attrs: {
          class: 'd277bc4d-a73e-4b2e-94ed-bbe7c1934b74',
        },
        autoresize_bottom_margin: 0,
        statusbar: false,
        toolbar: setting.toolbar,
        toolbar_drawer: 'sliding',
        quickbars_insert_toolbar: setting.quickbars_insert_toolbar,
        quickbars_selection_toolbar: setting.quickbars_selection_toolbar,
        paste_retain_style_properties: '',
        paste_postprocess: function(plugin, args) {
          $(args.node).find('*').removeAttr('style');
          $(args.node).find('*').removeAttr('class');
          list_fix(args.node);
        },
        paste_data_images: true,
        document_base_url: 'https://parti.xyz/',
        link_context_toolbar: true,
        target_list: false,
        relative_urls: false,
        remove_script_host : false,
        hidden_input: false,
        link_title: false,
        link_assume_external_targets: 'http',
        uploadimage_default_img_class: 'tinymce-content-image',
        content_css: content_css,
        formats: {
          strikethrough: {inline : 'del'}
        },
        valid_classes: '',
        valid_styles: '',
        extended_valid_elements : 'p[id,class],diffremoved,diffadded,cursorbr[id]',
        custom_elements : '~diffremoved,~diffadded',
      });

      $elm.on('parti-tinymce-conflict', function(e) {
        try {
          var content = tinyMCE.get($elm.attr('id')).getContent();
          var $content =$('<content>' + content + '</content>');
          $content.find('diffadded').contents().unwrap();
          $content.find('diffremoved').contents().unwrap();
          $content.find('difftouched').contents().unwrap();
          tinyMCE.get($elm.attr('id')).setContent($content.html());
        } catch(ignore) {}
      });
    });

    settings = {
      default: {
        plugins: 'link paste autolink lists advlist autoresize stickytoolbar-mobile hot-style',
        toolbar: 'bold italic strikethrough link blockquote | style-h1 style-h2 style-h3 bullist numlist outdent indent',
        forced_root_block: 'p',
      },
      wiki: {
        plugins: 'link paste autolink lists advlist autoresize stickytoolbar-mobile hot-style',
        toolbar: 'bold italic strikethrough link blockquote | style-h1 style-h2 style-h3 bullist numlist outdent indent',
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
        cache_suffix: '?v=5.0.12.0.2',
        language: 'ko_KR',
        plugins: setting.plugins,
        menubar: false,
        min_height: 200,
        autoresize_bottom_margin: 0,
        forced_root_block : setting.forced_root_block,
        forced_root_block_attrs: {
          class: 'd277bc4d-a73e-4b2e-94ed-bbe7c1934b74',
        },
        statusbar: false,
        toolbar: setting.toolbar,
        toolbar_drawer: 'sliding',
        paste_data_images: true,
        paste_retain_style_properties: '',
        paste_postprocess: function(plugin, args) {
          $(args.node).find('*').removeAttr('style');
          list_fix(args.node);
        },
        document_base_url: 'https://parti.xyz/',
        link_context_toolbar: false,
        link_assume_external_targets: 'http',
        target_list: false,
        relative_urls: false,
        remove_script_host : false,
        hidden_input: false,
        uploadimage_default_img_class: 'tinymce-content-image',
        link_title: false,
        content_css: content_css,
        body_class: 'tinymce-mobile',
        formats: {
          strikethrough: {inline : 'del'}
        },
        mobile: {
          theme: 'silver'
        },
        valid_classes: '',
        valid_styles: '',
        extended_valid_elements : 'p[id,class],diffremoved,diffadded,cursorbr[id]',
        custom_elements : '~diffremoved,~diffadded,~cursorbr',
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
          editor.on('keydown', _.throttle(function (e) {
            if(e.keyCode == 13) {
              $(editor.iframeElement).blur();
              $(editor.iframeElement).focus();
              uniqueId = "___cursor___" + Math.random().toString(36).substr(2, 16);
              editor.execCommand('mceInsertContent', false, "<cursorbr id=" + uniqueId + "></cursorbr>");
              editor.selection.select(editor.dom.select('#' + uniqueId)[0]);
              editor.selection.collapse(0);
              editor.dom.remove(uniqueId);
            }
          }, 500));
        },
      });

      $elm.on('parti-tinymce-conflict', function(e) {
        try {
          var content = tinyMCE.get($elm.attr('id')).getContent();
          var $content =$('<content>' + content + '</content>');
          $content.find('diffadded').contents().unwrap();
          $content.find('diffremoved').contents().unwrap();
          $content.find('difftouched').contents().unwrap();
          tinyMCE.get($elm.attr('id')).setContent($content.html());
        } catch(ignore) {}
      });
    });
  })();

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

  // wiki dirty check
  $.parti_apply($base, '.js-wiki-close-with-dirty-check', function(elm) {
    $(elm).on('click', function(e) {
      $elm = $(e.currentTarget);
      var editor_dom_id = $elm.data('wiki-close-with-dirty-check-editor-dom-id');
      if(tinyMCE.get(editor_dom_id) && tinyMCE.get(editor_dom_id).isDirty()) {
        if(confirm('위키를 닫겠습니까? 계속하면 변경사항이 저장되지 않습니다')) {
          return true;
        } else {
          e.preventDefault();
          return false;
        }
      }
    });
  });

  // wiki dirty check
  $.parti_apply($base, '.js-decision-close-with-dirty-check', function(elm) {
    $(elm).on('click', function(e) {
      $elm = $(e.currentTarget);
      var editor_dom_id = $elm.data('decision-close-with-dirty-check-editor-dom-id');
      if(tinyMCE.get(editor_dom_id).isDirty()) {
        if(confirm('토론 정리를 닫겠습니까? 계속하면 변경사항이 저장되지 않습니다')) {
          return true;
        } else {
          e.preventDefault();
          return false;
        }
      }
    });
  });
}

$(function() {
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
          $.scrollTo(0);

          var id = $($target.find('.js-tinymce').first()).attr('id');
          setTimeout(function () {
            try {
              tinyMCE.get(id).focus();
            } catch(ignore) {}
          }, 500);
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

});
