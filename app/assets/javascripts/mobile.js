$(function() {
  var $docu_height = $(document).height();
  var $device_width = $(window).width();
  var $mobile_list = $('.mobile-list');
  var $mobile_menu_btn = $('.btn-mobile-menu');
  var $mobile_menu_cancel = $('.mobile-list__close');
  var $navbar = $('.navbar');

  $mobile_menu_btn.on('click', function() {
    if ( $mobile_list.is(':visible') ) {
      $mobile_list.hide().animate({
        left: '-260px'
      }, 400 );
      $('body').css( {'margin-left':'0px', 'margin-right':'0px'} );
      $navbar.animate( {'right': '0'} );
    } else {
      $mobile_list.show().animate({
        left: '0px'
      }, 400 );
      $('body').animate( { marginRight: '-260px', marginLeft: '260px' } );
      $navbar.animate( {'right': '-260px'} );
    }
  });
  $mobile_menu_cancel.on('click', function() {
    $mobile_list.hide().animate({
      left: '-260px'
    }, 400 );
    $('body').css( {'margin-left':'0px', 'margin-right':'0px'} );
    $navbar.css( {'right': '0'} );
  });
});

