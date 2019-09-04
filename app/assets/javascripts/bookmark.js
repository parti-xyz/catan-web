var __parti_prepare_bookmark = function($base) {
  $.parti_apply($base, '.js-bookmark-tag-show-form', function(elm) {
    $(elm).on('click', function(e) {
      e.stopPropagation();
      var $form = $(e.currentTarget).closest('.js-bookmark-tag-show-form-container');

      $form.addClass('bookmark-tags-form-visible');
      $form.find('.js-bookmark-tag-show-form-control').focus();
    });
  });

  // 검색할 태그 선택하기
  $.parti_apply($base, '.js-bookmark-tag-searcher', function(elm) {
    $elm = $(elm);

    var fetch_tag_names = function() {
      var $selected_options = $elm.find(":selected");
      var tag_names = []
      $.each($selected_options, function(index, option) {
        tag_names.push($(option).val());
      });
      return tag_names;
    }

    var compare_array = function(array1, array2){
      // if the other array is a falsy value, return
      if (!array1) return false;
      if (!array2) return false;

      // compare lengths - can save a lot of time
      if (array1.length != array2.length)
          return false;

      for (var i = 0, l=array1.length; i < l; i++) {
          // Check if we have nested arrays
          if (array1[i] instanceof Array && array2[i] instanceof Array) {
              // recurse into the nested arrays
              if (!array1[i].equals(array2[i]))
                  return false;
          }
          else if (array1[i] != array2[i]) {
              // Warning - two different object instances will never be equal: {x:20} != {x:20}
              return false;
          }
      }
      return true;
    }

    var last_tag_names =  fetch_tag_names();
    var is_loading = false;

    $elm.selectpicker('render');
    $elm.parent().on('hide.bs.select', function(e) {
      if(is_loading) {
        return false;
      }

      var current_tag_names = fetch_tag_names();
      if(compare_array(last_tag_names, current_tag_names)) {
        return;
      }

      is_loading = true;

      $('.js-bookmark-posts-loading').show();
      $('.js-bookmark-posts').hide();

      $.ajax({
        url: $elm.data('url'),
        type: 'get',
        crossDomain: false,
        xhrFields: {
          withCredentials: true
        },
        data: {
          tag_names: fetch_tag_names(),
        },
        complete: function(xhr) {
          $('.js-bookmark-posts-loading').hide();
          $('.js-bookmark-posts').show();
          is_loading = false;
          last_tag_names = current_tag_names;
        },
      });
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
