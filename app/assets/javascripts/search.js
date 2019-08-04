var __parti_prepare_search = function($base) {
  // search
  $.parti_apply($base, '.js-header-search', function(elm) {
    var $elm = $(elm);

    var init_menu = function() {
      var active = 'all';
      if(__current_group_id()) {
        active = 'group';
      }
      if(__current_issue_id()) {
        active = 'issue';
      }

      if(active === 'group') {
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="all"]').show();
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="group"]').show().addClass('active');
      } else if(active === 'issue') {
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="all"]').show();
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="group"]').show();
        $elm.find('.js-header-search-dropdown-item[data-header-search-type="issue"]').show().addClass('active');
      }
      return active;
    }
    var init_active = init_menu();

    var handler_arrow_key = function(e){
      if(!$elm.find('.js-header-search-dropdown').is(':visible')) {
        return;
      }
      var $current_active = $elm.find('.js-header-search-dropdown-item.active').first();

      var $new_active = null;
      if(!$current_active || $current_active.length <= 0) {
        $new_active = $elm.find('.js-header-search-dropdown-item').first();
      } else {
        switch(e.which) {
          case 38: // up
            if(!$current_active || $current_active.length <= 0) {
              $new_active = $elm.find('.js-header-search-dropdown-item').last();
            } else {
              var $new_active = $current_active.prev('.js-header-search-dropdown-item');
              if(!$new_active || $new_active.length <= 0) {
                $new_active = $elm.find('.js-header-search-dropdown-item').last();
              }
            }
            break;
          case 40: // down
            if(!$current_active || $current_active.length <= 0) {
              $new_active = $elm.find('.js-header-search-dropdown-item').first();
            } else {
              var $new_active = $current_active.next('.js-header-search-dropdown-item');
              if(!$new_active || $new_active.length <= 0) {
                $new_active = $elm.find('.js-header-search-dropdown-item').first();
              }
            }
            break;
          default:
            break;
        }
        if($new_active && $new_active.length > 0) {
          $new_active.addClass('active');
          $current_active.removeClass('active');
          $elm.find('input[name="search_type"]').val($new_active.data('header-search-type'));
          e.preventDefault();
        }
      }
    }
    $(document).on('keydown', handler_arrow_key);

    var hide_menu = function() {
      $elm.find('.js-header-search-dropdown').hide();
    }
    var show_menu = function() {
      if(init_active != 'all') {
        $elm.find('.js-header-search-dropdown').show();
      }
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
      $elm.submit();
    });

    $elm.on('submit', function(e) {
      $elm.find('input[name="group_id"]').val(__current_group_id());
      $elm.find('input[name="issue_id"]').val(__current_issue_id());

      var current_search_type = $elm.find('input[name="search_type"]').val();
      if($.is_blank(current_search_type)) {
        $elm.find('input[name="search_type"]').val('all');
        if(__current_group_id()) {
          $elm.find('input[name="search_type"]').val('group');
        }
        if(__current_issue_id()) {
          $elm.find('input[name="search_type"]').val('issue');
        }
      }
    });
  });

  $.parti_apply($base, '.js-mobile-header-search', function(elm) {
    $(elm).on('click', function(e) {
      e.preventDefault();
      var href = $(e.currentTarget).attr('href');
      href += '?group_id=' + __current_group_id();
      href += '&issue_id=' + __current_issue_id();
      location.href = href;
    });
  });
}

$(function(){
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
});
