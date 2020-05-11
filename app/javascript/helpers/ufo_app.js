const ufo = (function () {
  const canHandle = function (handlerName) {
    const handler_versions = {
      'showWait': -1,
      'hideWait': -1,
      'setAutoWait': -1,
      'changeCurrentUrl': -1,
      'changeBasePageUrl': -1,
      'goBack': -1,
      'post': -1,
      'isApp': -1,
      'canHandle': -1,
      'startSocialSignIn': 3,
      'callbackSocialSignIn': 3,
    }
    const current_version = handler_versions[handlerName]
    if (current_version == undefined) {
      return false
    }

    return parseInt(this.version) >= current_version
  }

  if (window.webkit) {
    const handler = window.webkit.messageHandlers.ufop

    return {
      'showWait': function () {
        handler.postMessage({ 'method': 'showWait' })
      },
      'hideWait': function () {
        handler.postMessage({ 'method': 'hideWait' })
      },
      'setAutoWait': function (s) {
        handler.postMessage({ 'method': 'setAutoWait', 'arg0': (s ? '1' : '') })
      },
      'changeCurrentUrl': function (s) {
        handler.postMessage({ 'method': 'changeCurrentUrl', 'arg0': s })
      },
      'changeBasePageUrl': function (s) {
        handler.postMessage({ 'method': 'changeBasePageUrl', 'arg0': s })
      },
      'goBack': function () {
        handler.postMessage({ 'method': 'goBack' })
      },
      'startSocialSignIn': function (provider) {
        handler.postMessage({
          'method': 'startSocialSignIn',
          'arg0': provider
        })
      },
      'callbackSocialSignIn': function (provider) {
        handler.postMessage({
          'method': 'callbackSocialSignIn',
          'arg0': provider
        })
      },
      'post': function (action, json) {
        handler.postMessage({ 'method': 'post', 'arg0': action, 'arg1': JSON.stringify(json) })
      },
      'isApp': function () { return true },
      'canHandle': canHandle
    }
  }
  else if (typeof window.ufo == "undefined") {
    // 테스트 완료 후 console.log 지워주세요.
    return {
      "showWait": function () {
      },
      "hideWait": function () {
      },
      "setAutoWait": function (s) {
      },
      "goBack": function () {
      },
      'changeCurrentUrl': function (s) {
      },
      'changeBasePageUrl': function (s) {
      },
      'startSocialSignIn': function (s) {
      },
      'callbackSocialSignIn': function (s) {
      },
      "post": function (action, json) {
      },
      'isApp': function () { return false },
      'canHandle': function (name) { return false }
    }
  }
  else {
    window.ufo.post = function (a, j) {
      window.ufo.post_(a, JSON.stringify(j))
    }
    window.ufo.isApp = function () { return true }
    window.ufo.canHandle = canHandle
    return window.ufo
  }
})()

export default ufo;