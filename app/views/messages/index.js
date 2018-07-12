$('.js-notification-dropdown-menu').find('.js-notification-dropdown-loading').hide();
$('.js-notification-dropdown-menu').append('<%= j render('messages/list_on_header') %>');
$('.js-inactive-bell').show();
$('.js-active-bell').hide();
