var ws = new WebSocket("ws://localhost:8080/");

ws.onopen = function(event) {
    console.log("websocket open");
    var msg = {
        "event" : {
            "type" : "load",
            "srcElement" : null
        }
    };
    tell(msg);
};

ws.onmessage = function(event) {
    var req = JSON.parse(event.data);
    get(req);
};

ws.onclose = function(event) {
    console.log("websocket close");
};

ws.onerror = function(event) {
    console.log("error");
};

function get (req) {
    console.log(req);
    var content = req.content;
    var ret = null;
    if(req.callback_id !== null) {
        switch(content.type) {
            case "eval":
                ret = eval_js(content.argu);
                break;
            case "jquery":
                ret = call_jquery(content.argu);
                break;
        }
        msg = {
            "callback" : {
                "callback_id" : req.callback_id,
                "content" : ret
            }
        };
        tell(msg);
    } else {
    }
}

function tell (msg) {
    console.log(msg);
    ws.send(JSON.stringify(msg));
}

function eval_js (argu) {
    eval(argu);
}

function call_jquery (argu) {
    var ret = null;
    if(Elmtr[argu.method] === undefined) {
        ret = Elmtr["method_missing"](argu.trid, argu.method, argu.param);
    } else {
        ret = Elmtr[argu.method](argu.trid, argu.param);
    }
    return ret;
}

function ui_accessor_method (e, id) {
    var msg = {
        "event" : e
    };
    msg["event"]["elementId"] = id;
    delete msg["event"]["currentTarget"];
    delete msg["event"]["delegateTarget"];
    delete msg["event"]["fromElement"];
    delete msg["event"]["relatedTarget"];
    delete msg["event"]["target"];
    delete msg["event"]["toElement"];
    delete msg["event"]["view"];
    delete msg["event"]["originalEvent"];
    tell(msg);
}


// Element Transfer Manager

function ElementTr() {
    this.initialize.apply(this, arguments);
}

ElementTr.prototype = {
    initialize: function() {
        this.elms = {};
    },
    add: function(trid, param) {
        console.log(param);
        var elm = $(param.selector);
        if(elm.length !== 0) {
            this.elms[trid] = elm;
        }
        console.log(this.elms);
        return elm.length === 0 ? false : true;
    },
    bind: function(trid, param) {
        var elm = this.elms[trid];
        elm.bind(param.event, function(e) {
            ui_accessor_method(e, $(this).attr("id"));
        });
        return elm.length === 0 ? false : true;
    },
    method_missing: function(trid, method, param) {
        var elm = this.elms[trid];
        var this_obj = this;
        param = $.map(param, function(v, i) {
            if(v["jquery_obj"]) {
                return this_obj.elms[v["jquery_obj"]["trid"]];
            } else {
                return v;
            }
        });
        elm[method].apply(elm, param);
        // console.log(this.elms);
        return elm.length === 0 ? false : true;
    }
};

Elmtr = new ElementTr();
