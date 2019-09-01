var __parti_prepare_bookmark = function($base) {
  $.parti_apply($base, '.js-bookmark-tag-show-form', function(elm) {
    $(elm).on('click', function(e) {
      e.stopPropagation();
      var $form = $(e.currentTarget).closest('.js-bookmark-tag-show-form-container');

      $form.addClass('bookmark-tags-form-visible');
      $form.find('.js-bookmark-tag-show-form-control').focus();
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
