/*
import Elm.Kernel.Debug exposing (crash)
*/


var _ProOperate_productType = ProOperate().productType;

function _ProOperate_getTerminalId()
{
    return ProOperate().getTerminalID();
}

function _ProOperate_getFirmwareVersion()
{
    return ProOperate().getFirmwareVersion();
}

function _ProOperate_getContentsSetVersion()
{
    return ProOperate().getContentsSetVersion();
}

function _ProOperate_playSound(path)
{
    return _Scheduler_binding(function(callback)
    {
        var promise = new Promise(function (resolve) {
            function start(eventCode) {
                promise.then(function (id) {
                    callback(_Scheduler_succeed(id));
                }); 
            }
            var param = {
                filePath : path,
                loop : false,
                onEvent : start
            }
            var ret = ProOperate().playSound(param);
            if (ret < 0) {
                callback(_Scheduler_fail(ret));
            }
            else {
                resolve(ret);
            }
        });
    });
};

function _ProOperate_getKeypadDisplay()
{
    return _Scheduler_binding(function(callback)
    {
        var ret = ProOperate().getKeypadDisplay();
        if (typeof ret == 'object') {
            callback(_Scheduler_succeed(ret));
        }
        else {
            callback(_Scheduler_fail(ret));
        }
    });
}

function _ProOperate_setKeypadDisplay(display)
{
    return _Scheduler_binding(function(callback)
    {
        var ret = ProOperate().setKeypadDisplay(display);
        if (ret < 0) {
            callback(_Scheduler_fail(ret));
        }
        else {
            callback(_Scheduler_succeed(ret));
        }
    });
}

var _ProOperate_startKeypadListen = F2(function (toSuccessTask, toMsg)
{
    return _Scheduler_binding(function(callback)
    {
        function onEvent(eventCode) {
            var msg = A2(toMsg, "usb", eventCode);
            _Scheduler_rawSpawn(toSuccessTask(msg));
        }
        function onKeyDown(eventCode) {
            var msg = A2(toMsg, "keydown", eventCode);
            _Scheduler_rawSpawn(toSuccessTask(msg));
        }
        function onKeyUp(eventCode) {
            var msg = A2(toMsg, "keyup", eventCode);
            _Scheduler_rawSpawn(toSuccessTask(msg));
        }
        var param = {
            onKeyDown : onKeyDown,
            onKeyUp : onKeyUp,
            onEvent : onEvent
        };
        ProOperate().startKeypadListen(param);
        return function () { ProOperate().stopKeypadListen(); };
    });
});

function _ProOperate_stopKeypadListen()
{
    return ProOperate().stopKeypadListen();
}

function _ProOperate_getKeypadConnected()
{
    return ProOperate().getKeypadConnected();
}

function _ProOperate_toFelicaArray(elmConfig)
{
    var result = [];
    var xs = _List_toArray(elmConfig.felicas);
    for (var i = xs.length; i--; ) {
        var a = xs[i];
        a.services = _List_toArray(a.services);
        result.unshift({
            systemCode: a.systemCode,
            useMasterIDm: a.useMasterIDm,
            service: a.services
        });
    }
    return result;
}

function _ProOperate_toMifareArray(elmConfig)
{
    var result = [];
    var xs = _List_toArray(elmConfig.mifares);
    for (var i = xs.length; i--; ) {
        var a = xs[i];
        a.services = _List_toArray(a.services);
        result.unshift({
            type: a.type_,
            readData: a.services
        });
    }
    return result;
}

var _ProOperate_startCommunication_pro2 = F2(function (elmConfig, toError)
{
    var felicas = _ProOperate_toFelicaArray(elmConfig);
    var mifares = _ProOperate_toMifareArray(elmConfig);
    return _Scheduler_binding(function(callback)
    {
        /* 値をMaybeに */
        function _valueToMaybe(value) {
            if (value === undefined) {
                return elm$core$Maybe$Nothing;
            }
            else {
                return elm$core$Maybe$Just(value);
            }
        }
        /* Config設定 */
        var config = {
            successSound: elmConfig.successSound,
            failSound: elmConfig.failSound,
            successLamp: elmConfig.successLamp,
            failLamp: elmConfig.failLamp,
            waitLamp: elmConfig.waitLamp,
            felica: felicas,
            mifare: mifares,
            onetime: true,
            typeB: elmConfig.typeB,
            onEvent: undefined
        }
        var touchPromise = new Promise((resolve, reject) => {
            /* カード消失イベント時にTask完了 */
            config.onEvent = done;
            function done(eventCode, response) {
                if (eventCode == 1) {
                    resolve({
                        category: response.category,
                        paramResult: _valueToMaybe(response.paramResult),
                        auth: _valueToMaybe(response.auth),
                        idm: _valueToMaybe(response.idm),
                        data: _valueToMaybe(response.data),
                    });
                }
                else {
                    touchPromise.then(value => {
                        callback(_Scheduler_succeed(value));
                    });
                }
            }
        });
        /* カードポーリング実行 */
        try {
            var ret = ProOperate().startCommunication(config);
            if (ret < 0) {
                callback(_Scheduler_fail(toError(ret)));
            }
        }
        catch (e) {
            callback(_Scheduler_fail(e));
        }
    });
});

