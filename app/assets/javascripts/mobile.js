$(function() {
  var $docu_height = $(document).height();
  var $device_width = $(window).width();
  var $drawer_list = $('.drawer-list');
  var $drawer_menu_btn = $('.btn-drawer-menu');
  var $drawer_menu_cancel = $('.drawer-list__close');
  var $navbar = $('.navbar');

  $drawer_menu_btn.on('click', function() {
    if ( $drawer_list.is(':visible') ) {
      $drawer_list.hide().animate({
        left: '-260px'
      }, 400 );
      $('body').css( {'margin-left':'0px', 'margin-right':'0px'} );
      $navbar.animate( {'right': '0'} );
    } else {
      $drawer_list.show().animate({
        left: '0px'
      }, 400 );
      $('body').animate( { marginRight: '-260px', marginLeft: '260px' } );
    }
  });
  $drawer_menu_cancel.on('click', function() {
    $drawer_list.hide().animate({
      left: '-260px'
    }, 400 );
    $('body').css( {'margin-left':'0px', 'margin-right':'0px'} );
    $navbar.css( {'right': '0'} );
  });
});

