(function() {
  $.rails.prompt = function(message, defaultValue) {
    return window.prompt(message, defaultValue)
  }

  $.rails.handlePrompt = function(element) {
    var config = element.data('prompt')
    var message = config.message || config
    var defaultValue = config.default
    var param = config.param || 'value'

    if (!message) { return true }

    if ($.rails.fire(element, 'prompt')) {
      var value = $.rails.prompt(message, defaultValue)
      var callback = $.rails.fire(element, 'prompt:complete', [value])
    }

    if (value) {
      if (!element.data("remote")) {
        var query_symbol = (/[?].+[=]/.test(element.attr("href"))) ? "&" : "?"
        element.attr("href", element.attr("href") + query_symbol + param + "=" + value)
      }
      var params = element.data('params') || {}
      params[param] = value
      element.data('params', params)
    }

    return value && callback
  }

  allowAction = $.rails.allowAction
  $.rails.allowAction = function(element) {
    if (element.data('prompt')) {
      return $.rails.handlePrompt(element)
    } else {
      return allowAction(element)
    }
  }
})()