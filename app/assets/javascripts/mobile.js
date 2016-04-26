$(function() {
  var $docu_height = $(document).height();
  var $mobile_list = $('.mobile-list');
  var $mobile_menu_btn = $('.btn-mobile-menu');
  var $mobile_menu_cancel = $('.mobile-list__close');
  var $navbar = $('.navbar');


  $mobile_list.css('height', $docu_height);

  $mobile_menu_btn.on('click', function() {
    if ( $mobile_list.is(':visible') ) {
      $mobile_list.hide().animate({
        right: '-260px'
      }, 400 );
      $('body').css( {'margin-left':'0px', 'margin-right':'0px'} );
      $navbar.animate( {'left': '0'} );
    } else {
      $mobile_list.show().animate({
        right: '0px'
      }, 400 );
      $('body').animate( { marginLeft: '-260px', marginRight: '260px' } );
      $navbar.animate( {'left': '-260px'} );
    }
  });
  $mobile_menu_cancel.on('click', function() {
    $mobile_list.hide().animate({
      right: '-260px'
    }, 400 );
    $('body').css( {'margin-left':'0px', 'margin-right':'0px'} );
    $navbar.css( {'left': '0'} );
  });

});

