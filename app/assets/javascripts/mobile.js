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

// mobile-list height
var page = document.getElementById('mobile-list'),
    ua = navigator.userAgent,
    iphone = ~ua.indexOf('iPhone') || ~ua.indexOf('iPod'),
    ipad = ~ua.indexOf('iPad'),
    ios = iphone || ipad,
    fullscreen = window.navigator.standalone,
    android = ~ua.indexOf('Android'),
    lastWidth = 0;
if (android) {
  window.onscroll = function() {
    page.style.height = window.innerHeight + 'px'
  }
}
var setupScroll = window.onload = function() {
  if (ios) {
    var height = document.documentElement.clientHeight;
    if (iphone && !fullscreen) height += 80;
    page.style.height = height + 'px';
  } else if (android) {
    page.style.height = (window.innerHeight + 56) + 'px'
  }
  setTimeout(scrollTo, 0, 0, 1);
};
(window.onresize = function() {
  var pageWidth = page.offsetWidth;
  if (lastWidth == pageWidth) return;
  lastWidth = pageWidth;
  setupScroll();
})();