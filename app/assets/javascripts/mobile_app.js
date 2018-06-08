var ufo = (function() {
    var canHandle = function(name) {
        if(this.version == undefined || name == null) {
            return false;
        }

        if(name == 'startGoogleSignIn' || name == 'startFacebookSignIn') {
            return this.version >= '3'
        }

        return true;
    }

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
            'startGoogleSignIn': function() {
                handler.postMessage({'method':'startGoogleSignIn'});
            },
            'startFacebookSignIn': function() {
                handler.postMessage({'method':'startFacebookSignIn'});
            },
            'post': function(action,json) {
                handler.postMessage({'method':'post', 'arg0':action, 'arg1':JSON.stringify(json)});
            },
            'isApp': function() { return true; },
            'canHandle': canHandle
        }
    }
    else if (typeof ufo == "undefined")
    {
        // 테스트 완료 후 console.log 지워주세요.
        return {
            "showWait": function() {
            },
            "hideWait": function() {
            },
            "setAutoWait": function(s) {
            },
            "goBack": function() {
            },
            'changeCurrentUrl': function(s) {
            },
            'changeBasePageUrl': function(s) {
            },
            'startGoogleSignIn': function() {
            },
            'facebookSignIn': function() {
            },
            "post": function(action,json) {
            },
            'isApp': function() { return false; },
            'canHandle': function(name) { return false; }
        };
    }
    else
    {
        ufo.post = function(a,j) {
            ufo.post_(a, JSON.stringify(j));
        };
        ufo.isApp = function() { return true; };
        ufo.canHandle = canHandle;
        return ufo
    }
})();
