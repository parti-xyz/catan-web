(function () {
  var scrollPosition;
  var focusId;

  function reload() {
      Turbolinks.visit(window.location.toString(), {action: 'replace'})
  }

  document.addEventListener('turbolinks:before-render', function () {
      scrollPosition = [window.scrollX, window.scrollY];
      focusId = document.activeElement.id;
  });
  document.addEventListener('turbolinks:load', function () {
      if (scrollPosition) {
          window.scrollTo.apply(window, scrollPosition);
          scrollPosition = null
      }
      if (focusId) {
          document.getElementById(focusId).focus();
          focusId = null;
      }
  });
  return reload();
})();
