var ufo = (function() {
    if (window.webkit)
    {
        var handler = window.webkit.messageHandlers.ufop;

        return {
            'showWait': function() {
                handler.postMessage({'method':'showWait'});
            },
            'hideWait': function() {
                handler.postMessage({'method':'hideWait'});
            },
            'setAutoWait': function(s) {
                handler.postMessage({'method':'setAutoWait', 'arg0':(s?'1':'')});
            },
            'changeCurrentUrl': function(s) {
                handler.postMessage({'method':'changeCurrentUrl', 'arg0':s});
            },
            'changeBasePageUrl': function(s) {
                handler.postMessage({'method':'changeBasePageUrl', 'arg0':s});
            },
            'goBack': function() {
                handler.postMessage({'method':'goBack'});
            },
            'canGoBack': function() {
                handler.postMessage({'method':'canGoBack'});
            },
            'callback': {
                'canGoBack': function(canGoBack) {}
            },
            'post': function(action,json) {
                handler.postMessage({'method':'post', 'arg0':action, 'arg1':JSON.stringify(json)});
            },
            'isApp': function() { return true; }
        }
    }
    else if (typeof ufo == "undefined")
    {
        // 테스트 완료 후 console.log 지워주세요.
        return {
            "showWait": function() {
                console.log("showWait()");
            },
            "hideWait": function() {
                console.log("hideWait()");
            },
            "setAutoWait": function(s) {
                console.log("setAutoWait(%s)",s);
            },
            "goBack": function() {
                console.log("goBack()");
            },
            'changeCurrentUrl': function(s) {
                console.log("changeCurrentUrl()");
            },
            'changeBasePageUrl': function(s) {
                console.log("changeBasePageUrl()");
            },
            'canGoBack': function() {
                console.log("canGoBack()");
            },
            'callback': {
                'canGoBack': function(canGoBack) {}
            },
            "post": function(action,json) {
                console.log("UfoPost(%s,%s)", action, JSON.stringify(json));
            },
            'isApp': function() { return false; },
        };
    }
    else
    {
        ufo.post = function(a,j) {
            ufo.post_(a, JSON.stringify(j));
        };
        ufo.isApp = function() { return true; };
        return ufo
    }
})();
