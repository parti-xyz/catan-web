if (window.webkit)
{
    var handler = window.webkit.messageHandlers.ufop;
    ufo = {
        'showWait': function() {
            handler.postMessage({'method':'showWait'});
        },
        'hideWait': function() {
            handler.postMessage({'method':'hideWait'});
        },
        'setAutoWait': function(s) {
            handler.postMessage({'method':'setAutoWait', 'arg0':(s?'1':'')});
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
    ufo = {
        "showWait": function() {
            console.log("showWait()");
        },
        "hideWait": function() {
            console.log("hideWait()");
        },
        "setAutoWait": function(s) {
            console.log("setAutoWait(%s)",s);
        },
        "post": function(action,json) {
            console.log("UfoPost(%s,%s)", action, JSON.stringify(json));
        },
        'isApp': function() { return false; }
    };
}
else
{
    ufo.post = function(a,j) {
        ufo.post_(a, JSON.stringify(j));
    };
    ufo.isApp = function() { return true; };
}
