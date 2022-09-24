/*

import Elm.Kernel.Debug exposing (crash)

*/

var _WebSQL_openDatabase = F4(function (name, version, desc, size)
{
    return _Scheduler_binding(function(callback)
    {
        try {
            var db = openDatabase(name, version, desc, size);
            callback(_Scheduler_succeed(db));
        }
        catch (e) {
            console.log("exception = "+JSON.stringify(e));
            callback(_Scheduler_fail(e.message));
        }
    });
});

function _WebSQL_transaction(db)
{
    return _Scheduler_binding(function(callback)
    {
        function success(tx) {
            callback(_Scheduler_succeed(tx));
        }

        function error(e) {
            callback(_Scheduler_fail(e.message));
        }

        db.transaction(success, error);
    });
}

var _WebSQL_executeSql = F3(function (sql, params, tx)
{
    return _Scheduler_binding(function(callback)
    {
        function success(tx, rs) {
            var result = [];
            for (var i = rs.rows.length; i--; ) {
                result.unshift(rs.rows.item(i));
            }
            callback(_Scheduler_succeed((tx, JSON.stringify(result))));
        }

        function error(e) {
            callback(_Scheduler_fail(JSON.stringify(e)));
        }
        var xs = _List_toArray(params).map(function (r) { return r.a });
        console.log("params = "+JSON.stringify(xs));
        tx.executeSql(sql, xs, success, error);
    });
});
