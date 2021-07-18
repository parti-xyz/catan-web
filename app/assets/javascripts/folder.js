var __parti_prepare_folder = function($base) {
  // 폴더 목록의 폴더나 아이템 클릭/더블클릭
  (function() {
    var delay = 700;

    $.parti_apply($base, '.js-folder-item', function(elm) {
      var $elm = $(elm);
      var $rename_form_container_elm = $elm.find('.js-folder-item-rename-form-container');
      var $rename_form_elm = $rename_form_container_elm.find('form').first();
      var $rename_title_field_elm = $elm.find('.js-folder-item-rename-text-field');
      var $content_elm = $elm.find('.js-folder-item-renamable-content');
      var $folder_menu = $elm.find('.js-folder-item-menu');

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
        $elm.removeClass('renaming');
      }

      var reset_item = function($current_elm, active) {
        $current_elm.find('.js-folder-item-rename-form-container').hide();
        $current_elm.find('.js-folder-item-renamable-content').show();
      }

      var text_field_width = function(text) {
        var original_text = $content_elm.text();

        $content_elm.text(text);
        var text_width = $content_elm.outerWidth();
        $content_elm.text(original_text);

        var parent_width = $content_elm.parent().parent().outerWidth();
        return Math.min(text_width, parent_width - 110);
      }

      var on_run = function(e) {
        clearTimeout($elm.data('timeout')); //prevent single-click action

        if($elm.data('folder-item-type') === 'folder') {
          $elm.siblings('.js-folder-children').first().slideToggle(100, function() {
            var _cookies_folder_ids = Cookies.getJSON('opened_folder_ids') || [];
            var folder_id = $elm.data('folder-item-id');
            if($(this).is(':visible')) {
              $elm.find('.js-folder-item-icon').removeClass('fa-folder').addClass('fa-folder-open');
              _cookies_folder_ids.push(folder_id);
            } else {
              $elm.find('.js-folder-item-icon').removeClass('fa-folder-open').addClass('fa-folder');
              _.pull(_cookies_folder_ids, folder_id);
            }

            $.each($elm.siblings('.js-folder-children'), function(index, children_container_elm) {
              $children_container_elm = $(children_container_elm);
              $children_elms = $children_container_elm.find('.js-folder-children').hide();
              $.each($children_container_elm.find('.js-folder-item[data-folder-item-type="folder"]'), function(index_, child_elm) {
                var $child_elm = $(child_elm);
                var folder_id = $child_elm.data('folder-item-id');
                $child_elm.find('.js-folder-item-icon').removeClass('fa-folder-open').addClass('fa-folder');
                 _.pull(_cookies_folder_ids, folder_id);
              });
            });

            _cookies_folder_ids = _.uniq(_cookies_folder_ids);
            if(_cookies_folder_ids.length > 500) {
              _cookies_folder_ids.shift()
            }
            Cookies.set('opened_folder_ids', _cookies_folder_ids, { domain: '.' + __root_domain, expires: 7 });
          });
        }
        if($elm.data('folder-item-type') === 'post') {
          var closest = function(el, fn) {
            if(!$elm.has(elm)) {
              return null;
            }
            return el && (fn(el) ? el : closest(el.parentNode, fn));
          }
          var $closest_post_url_elm = $(closest(e.target, function(elmx) {
            return !!$(elmx).data("post-url");
          }));

          if($closest_post_url_elm.length <= 0) {
            return;
          }

          e.preventDefault();
          var url = $closest_post_url_elm.data("post-url");
          if(!url) { return; }

          if (e.shiftKey || e.ctrlKey || e.metaKey) {
            window.open(url, '_blank');
          } else {
            window.location.href  = url;
          }
        }
        reset_item($elm, true); //after action performed, reset counter
      }

      var on_resize_rename_title_field = function() {
        var width = text_field_width($rename_title_field_elm.val());
        $rename_title_field_elm.css({ width: width });
      }
      on_resize_rename_title_field();

      var on_rename = function() {
        on_resize_rename_title_field();
        var title = $content_elm.data('value');
        $rename_title_field_elm.val(title).trigger('input');
        $rename_form_container_elm.show();
        $content_elm.hide();

        $(document).on('keyup.folder-item', esc_handler);
        $rename_title_field_elm.on('blur.folder-item', on_blur);

        $rename_title_field_elm.focus();
        $rename_title_field_elm[0].setSelectionRange(0, 0);
        $rename_title_field_elm[0].scrollLeft = 0;

        $elm.addClass('renaming');
      }

      $elm.on('dblclick', function(e) {
        e.preventDefault();
      });

      $elm.on('mouseleave', function(e) {
        // dropdown reset
        if($folder_menu.hasClass('open')) {
          $folder_menu.find('[data-toggle="dropdown"]').dropdown('toggle');
        }
      });

      $elm.on('click', function(e) {
        if($(e.target).closest('.js-folder-item-no-run').length > 0) {
          return;
        }

        if($elm.hasClass('js-blured')) {
          return;
        }

        $('.js-folder-item').each(function(index, current_elm) {
          reset_item($(current_elm));
        });
        on_run(e);
      });

      $elm.on('parti-folder-item-force-rename', function(e, data) {
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

      $elm.on('parti-folder-item-submit', function(e) {
        $rename_form_elm.submit();
      });

      $rename_form_elm.on('submit', function(e) {
        $elm.trigger('parti-folder-item-saving');
        var title = $rename_title_field_elm.val();
        $content_elm.html(title + ' <i class="fa fa-spinner fa-pulse">');
        on_blur();
      });

      // 하이라이트
      $elm.on('parti-folder-highlight', function(e) {
        $.each($elm.parents('.js-folder-children').toArray().reverse(), function(index, children) {
          var $children = $(children);
          if($children.is(':visible')) {
            return;
          }

          $children.slideToggle(100, function() {
            var _cookies_folder_ids = (Cookies.getJSON('opened_folder_ids') || []);

            var $folder_items = $children.siblings('.js-folder-item');
            $.each($folder_items, function(index, folder_item) {
              var $folder_item = $(folder_item);
              $folder_item.find('.js-folder-item-icon').removeClass('fa-folder').addClass('fa-folder-open');
              var folder_id = $folder_item.data('folder-item-id');
              _cookies_folder_ids.push(folder_id);
            });

            _cookies_folder_ids = _.uniq(_cookies_folder_ids);
            if(_cookies_folder_ids.length > 500) {
              _cookies_folder_ids.shift()
            }
            Cookies.set('opened_folder_ids', _cookies_folder_ids, { domain: '.' + __root_domain, expires: 7 });
          });
        });


        if(!$.viewport('inviewport', $elm, {threshold : 100})) {
          $(document).scrollTo($elm, {
            offset: { top: -100 },
            onAfter: function() {
              $elm.addClass('stress');
              setTimeout(function() { $elm.removeClass('stress'); }, 3000);
            }
          });
        } else {
          $elm.addClass('stress');
          setTimeout(function() { $elm.removeClass('stress'); }, 3000);
        }
      });
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
        $('.js-slug-folder-status-display').text('저장 중...');
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
          delay: 400,
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

            // 폴더 들여쓰기 스타일링
            try {
              var $folderItem = null;
              if($item.hasClass('js-folder-item')) {
                $folderItem = $item
              } else {
                $folderItem = $item.find('.js-folder-item').first();
              }
              $folderItem.data('folder-depth', (parseInt($container.data('folder-depth') || '1')));
            } catch(error) { }
            $(document).trigger('parti-folder-indentation');

            // 서버에 저장
            if(container) {
              var data;
              if(container.el.hasClass('js-draggable-slug-folder-container-root')) {
                data = container.el.sortable('serialize').get();
              } else {
                data = container.el.parent().closest('.js-draggable-slug-folder-container').sortable('serialize').get();
              }
              payload_json = JSON.stringify(data, null, ' ');
              autosave_payload($item.data('draggable-slug-folder-json-params'));
            } else {
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
            return (container_type === 'any' || $item.data('draggable-slug-folder-item-type') == container_type);
          },
        });

        $base_elm.data('sortable-group', group);
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
    });
  })();

  // 이동할 폴더 정하기
  $.parti_apply($base, '.js-choose-folder-to-move', function(elm) {
    $(elm).on('click', function(e) {
      var $elm = $(e.currentTarget);
      var $move_to_link = $($elm.data('move-to-link'));

      $elm.siblings().removeClass('active');
      if($elm.hasClass('active')) {
        $elm.removeClass('active');
        $move_to_link.addClass('disabled');
        $move_to_link.data('folder-id', '');
        $move_to_link.find('.js-move-folder-here').show();
      } else {
        $elm.addClass('active');
        $move_to_link.removeClass('disabled');
        $move_to_link.data('folder-id', $elm.data('folder-id'));
        $move_to_link.find('.js-move-folder-here').hide();
      }
    });
  });

  // 정한 폴더로 이동하기
  $.parti_apply($base, '.js-move-folder', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();

      var $elm = $(e.currentTarget);
      var folder_id = $elm.data('folder-id');

      if(folder_id || folder_id == 0) {
        $.ajax({
          url: $elm.attr('href'),
          type: "post",
          data:{ parent_id: folder_id },
          crossDomain: false,
          xhrFields: {
            withCredentials: true
          }
        });
      }
    });
  });

  // 게시글 저장할 폴더 정하기
  $.parti_apply($base, '.js-choose-folder-to-new-post', function(elm) {
    $(elm).on('click', function(e) {
      var $elm = $(e.currentTarget);
      var $choice_link = $($elm.data('choice-link'));

      var $btn = $(e.target).closest('.js-choose-folder-to-new-post-link-btn');
      if ($btn && $btn.length > 0) {
        return true;
      }

      $elm.siblings().removeClass('active');
      $elm.siblings().find('.js-choose-folder-to-new-post-link-btn').removeClass('btn-primary').addClass('btn-default');
      if($elm.hasClass('active')) {
        $elm.removeClass('active');
        $elm.find('.js-choose-folder-to-new-post-link-btn');
        $choice_link.addClass('disabled');
        $choice_link.data('folder-id', '');
        $choice_link.data('folder-full-title', '');
        $choice_link.find('.js-choose-folder-here').show();
      } else {
        $elm.addClass('active');
        $elm.find('.js-choose-folder-to-new-post-link-btn');
        $choice_link.removeClass('disabled');
        $choice_link.data('folder-id', $elm.data('folder-id'));
        $choice_link.data('folder-full-title', $elm.data('folder-full-title'));
        $choice_link.find('.js-choose-folder-here').hide();
      }
    });
  });

  // 정한 폴더에 새 게시글 위치하기
  $.parti_apply($base, '.js-confirm-folder-to-new-post', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();

      var $elm = $(e.currentTarget);
      var $full_title_dom = $('#' + $elm.data('new-post-folder-full-title-dom'));
      var $id_dom = $('#' + $elm.data('new-post-folder-id-dom'));
      var folder_id = $elm.data('folder-id');
      var folder_full_title = $elm.data('folder-full-title');

      if(folder_id || folder_id == 0) {
        $(document).trigger('parti-close-modal-placeholder');
        $full_title_dom.find('.js-new-post-folder-full-title-only-exists').show();
        $full_title_dom.find('.js-new-post-folder-full-titler').html(folder_full_title);
        $id_dom.val(folder_id);
      }
    });
  });

  // 정한 폴더 삭제하기
  $.parti_apply($base, '.js-new-post-folder-clear', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();

      var $elm = $(e.currentTarget);
      var $full_title_dom = $('#' + $elm.data('new-post-folder-full-title-dom'));
      var $id_dom = $('#' + $elm.data('new-post-folder-id-dom'));

      $full_title_dom.find('.js-new-post-folder-full-title-only-exists').hide();

      $full_title_dom.find('.js-new-post-folder-full-titler').html('');
      $id_dom.val(null);
    });
  });

  // 새 게시글을 새폴더에 지정하기
  $.parti_apply($base, '.js-new-post-folder-id-field', function(elm) {
    $(elm).on('parti-new-folder-for-new-post', function(e, folder_id, folder_full_title) {
      var $elm = $(e.currentTarget);
      var $full_title_dom = $('#' + $elm.data('new-post-folder-full-title-dom'));

      if(folder_id || folder_id == 0) {
        $full_title_dom.find('.js-new-post-folder-full-title-only-exists').show();

        $full_title_dom.find('.js-new-post-folder-full-titler').html(folder_full_title);
        $elm.val(folder_id);
      }
    });
  });
}

$(function(){
  parti_prepare($('body'));

  // 폴더 들여쓰기 스타일링
  (function() {
    var folder_indentation = function() {
      $.each($('.js-folder-item'), function(index, elm) {
        try {
          var $elm = $(elm);
          $elm.css('padding-left', (parseInt($elm.data('folder-depth') || '1') - 1) * 16 + "px");
        } catch(error) { }
      });
    }
    $(document).on('parti-folder-indentation', folder_indentation);

  })();
});