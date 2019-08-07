var __parti_prepare_post = function($base) {
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

  // 게시글 모두 읽음 표시 업데이트
  (function() {
    $.parti_apply($base, '.js-post-new-stroked-read-all-post-auto', function(elm) {
      var $elm = $(elm);
      var timer;
      $elm.data('read-all-posts-destroy-waypoint', $elm.waypoint({
        handler: function(direction) {
          if(timer) {
            return;
          }
          if($elm.attr('href') != '#') {
            timer = setTimeout(function() {
              if($elm.attr('href') != '#') {
                $.ajax({
                  url: $elm.attr('href'),
                  type: "post",
                });
              }
              clearTimeout(timer);
            }, 10 * 1000);
          }
          this.destroy();
          clear_auto($elm);
        },
        offset: "80%"
      })[0]);

      var clear_auto = function($auto_elm) {
        var waypoint = $auto_elm.data('read-all-posts-destroy-waypoint');
        if(waypoint) {
          waypoint.destroy();
        }
        $auto_elm.data('read-all-posts-destroy-waypoint', null);
      }

      $elm.on('parti-post-new-stroked-clear-auto', function(e) {
       clear_auto($elm);
      });
    });

    $.parti_apply($base, '.js-post-new-stroked', function(elm) {
      var $elm = $(elm);

      $elm.on('parti-post-new-stroked-clear-all', function(e) {
        $($(e.currentTarget).find('.js-post-new-stroked-read-all-post-auto')).trigger('parti-post-new-stroked-clear-auto');
        $elm.remove();
      });

      $elm.on('parti-post-new-stroked-disable-all', function(e) {
        $($(e.currentTarget).find('.js-post-new-stroked-read-all-post-auto')).trigger('parti-post-new-stroked-clear-auto');
        $elm.addClass('js-post-new-stroked-disable disable');
        $.each($elm.find('.js-post-new-stroked-label'), function(index, label) {
          $(label).html($(label).data('post-new-stroked-label-read-all'));
        });
        $elm.find('.js-post-new-stroked-link').attr('href', '#');
      });

      $($elm.find('.js-post-new-stroked-link')).on('click', function(e) {
        if(!$elm.hasClass('js-post-new-stroked-disable')) {
          return true;
        }
        e.preventDefault();
        return false;
      });
    });
  })();
}

var parti_prepare_comment = function(comment_form_control_selector, nickname, text) {
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

$(function(){
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
        url: $waypoint_element.data('list-url'),
        type: "get",
        data:{
          previous_post_last_stroked_at_timestamp: $container.data('previous-post-last-stroked-at-timestamp'),
          first_post_last_stroked_at_timestamp: $container.data('first-post-last-stroked-at-timestamp')
        },
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

    load_page($('.js-page-waypoint'));

    var unread_until_issue_post = function($waypoint_element, $event_target) {
      var until_post_last_stroked_at_timestamp = $event_target.data('until-post-last-stroked-at-timestamp');
      if(!until_post_last_stroked_at_timestamp) {
        return;
      }
      var until_post_id = $event_target.data('until-post-id');
      if(!until_post_id) {
        return;
      }

      var $container = $($waypoint_element.data('target'));

      $.ajax({
        url: $waypoint_element.data('read-all-url'),
        type: "post",
        data:{
          until_post_last_stroked_at_timestamp: until_post_last_stroked_at_timestamp,
          until_post_id: until_post_id,
          first_post_last_stroked_at_timestamp: $container.data('first-post-last-stroked-at-timestamp'),
        }
      });
    }

    $('.js-page-waypoint').on('parti-post-page-waypoint-unread-until-post', function(e) {
      unread_until_issue_post($(e.currentTarget), $(e.target));
    });
  })();
})
