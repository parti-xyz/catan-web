$(function () {
    // Pass authenticity_token
    var params = '[name="authenticity_token"]';
    // Set global settings
    $.Redactor.settings = {
        //plugins: ['source', 'fullscreen', 'textdirection', 'clips'],
        imageUpload: '/redactor2_rails/images',
        imageUploadFields: params,
        fileUpload: '/redactor2_rails/files',
        fileUploadFields: params,
        lang: 'ko'
    };
    // Initialize Redactor
    $('.redactor').redactor({
      buttons: ['format', 'bold', 'italic', 'deleted', 'lists', 'image', 'link', 'horizontalrule'],
      callbacks: {
        imageUploadError: function(json, xhr) {
          UnobtrusiveFlash.showFlashMessage(json.error.data[0], {type: 'notice'})
        }
      },
      toolbarFixedTopOffset: 60
    });
});

