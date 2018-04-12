/*

import Debugger.Main as Main exposing (wrapView, wrapInit, wrapUpdate, wrapSubs, cornerView, popoutView, Up, Down)
import Elm.Kernel.Browser exposing (toEnv, makeAnimator)
import Elm.Kernel.List exposing (Cons, Nil)
import Elm.Kernel.Platform exposing (initialize)
import Elm.Kernel.Scheduler exposing (nativeBinding, succeed)
import Elm.Kernel.Utils exposing (Tuple0, Tuple2)
import Elm.Kernel.VirtualDom exposing (node, applyPatches, diff, doc, makeStepper, render, virtualize)
import Json.Decode as Json exposing (map)
import List exposing (map, reverse)
import Maybe exposing (Just, Nothing)
import Set exposing (foldr)
import Dict exposing (foldr, empty, insert)
import Array exposing (foldr)

*/



// HELPERS


function _Debugger_unsafeCoerce(value)
{
	return value;
}



// PROGRAMS


var _Debugger_embed = F4(function(impl, flagDecoder, debugMetadata, object)
{
	object['embed'] = function(node, flags)
	{
		return __Platform_initialize(
			flagDecoder,
			flags,
			A3(__Main_wrapInit, debugMetadata, _Debugger_popout(), impl.__$init),
			__Main_wrapUpdate(impl.__$update),
			__Main_wrapSubs(impl.__$subscriptions),
			_Debugger_makeStepperBuilder(node, impl.__$view)
		);
	};
	return object;
});


var _Debugger_fullscreen = F4(function(impl, flagDecoder, debugMetadata, object)
{
	object['fullscreen'] = function(flags)
	{
		return __Platform_initialize(
			A2(__Json_map, __Browser_toEnv, flagDecoder),
			flags,
			A3(__Main_wrapInit, debugMetadata, _Debugger_popout(), impl.__$init),
			__Main_wrapUpdate(impl.__$update),
			__Main_wrapSubs(impl.__$subscriptions),
			_Debugger_makeStepperBuilder(__VirtualDom_doc.body, function(model) {
				var ui = impl.__$view(model);
				if (__VirtualDom_doc.title !== ui.__$title)
				{
					__VirtualDom_doc.title = ui.__$title;
				}
				return __VirtualDom_node('body')(__List_Nil)(ui.__$body);
			})
		);
	};
	return object;
});


function _Debugger_popout()
{
	return { __doc: undefined, __isClosed: true };
}

function _Debugger_isOpen(popout)
{
	return !popout.__isClosed;
}

function _Debugger_open(popout)
{
	popout.__isClosed = false;
	return popout
}


function _Debugger_makeStepperBuilder(appNode, view)
{
	return function(sendToApp, initialModel)
	{
		var currApp = __VirtualDom_virtualize(appNode);
		var currCorner = __Main_cornerView(initialModel);
		var currPopout;

		var cornerNode = __VirtualDom_render(currCorner, sendToApp);

		return __Browser_makeAnimator(initialModel, function(model)
		{
			var nextApp = view(model);
			var appPatches = __VirtualDom_diff(currApp, nextApp);
			appNode = __VirtualDom_applyPatches(appNode, currApp, appPatches, sendToApp);
			currApp = nextApp;

			// view corner

			if (model.__$popout.__isClosed)
			{
				var nextCorner = __cornerView(model);
				var cornerPatches = __VirtualDom_diff(currCorner, nextCorner);
				cornerNode = __VirtualDom_applyPatches(cornerNode, currCorner, cornerPatches, sendToApp);
				currCorner = nextCorner;
				cornerNode.parentNode === appNode || appNode.appendChild(cornerNode);
				return;
			}

			cornerNode.parentNode && cornerNode.parentNode.removeChild(cornerNode);

			// view popout

			model.__$popout.__doc || (currPopout = _Debugger_openWindow(model.__$popout, sendToApp));

			__VirtualDom_doc = model.__$token.__doc; // SWITCH TO POPOUT DOC
			var nextPopout = __Main_popoutView(model);
			var popoutPatches = __VirtualDom_diff(currPopout, nextPopout);
			__VirtualDom_applyPatches(model.__$popout.__doc.body, currPopout, popoutPatches, sendToApp);
			currPopout = nextPopout;
			__VirtualDom_doc = document; // SWITCH BACK TO NORMAL DOC
		});
	};
}



// POPOUT


function _Debugger_openWindow(popout, sendToApp)
{
	var w = 900, h = 360, x = screen.width - w, y = screen.height - h;
	var debuggerWindow = window.open('', '', 'width=' + w + ',height=' + h + ',left=' + x + ',top=' + y);
	var doc = debuggerWindow.document;
	doc.title = 'Elm Debugger';
	doc.body.style.margin = '0';
	doc.body.style.padding = '0';

	// handle arrow keys
	doc.addEventListener('keydown', function(event) {
		event.metaKey && event.which === 82 && window.location.reload();
		event.which === 38 && (sendToApp(__Main_Up), event.preventDefault());
		event.which === 40 && (sendToApp(__Main_Down), event.preventDefault());
	});

	// handle window close
	window.addEventListener('unload', close);
	debuggerWindow.addEventListener('unload', function() {
		popout.__doc = undefined;
		popout.__isClosed = true;
		window.removeEventListener('unload', close);
	});
	function close() {
		popout.__doc = undefined;
		popout.__isClosed = true;
		debuggerWindow.close();
	}

	// register new window
	popout.__doc = doc;
	popout.__isClosed = false;
	return __VirtualDom_virtualize(doc.body);
}



// SCROLL


function _Debugger_scroll(popout)
{
	return __Scheduler_nativeBinding(function(callback)
	{
		if (popout.__doc)
		{
			var msgs = popout.__doc.getElementsByClassName('debugger-sidebar-messages')[0];
			if (msgs)
			{
				msgs.scrollTop = msgs.scrollHeight;
			}
		}
		callback(__Scheduler_succeed(__Utils_Tuple0));
	});
}



// UPLOAD


function _Debugger_upload()
{
	return __Scheduler_nativeBinding(function(callback)
	{
		var element = document.createElement('input');
		element.setAttribute('type', 'file');
		element.setAttribute('accept', 'text/json');
		element.style.display = 'none';
		element.addEventListener('change', function(event)
		{
			var fileReader = new FileReader();
			fileReader.onload = function(e)
			{
				callback(__Scheduler_succeed(e.target.result));
			};
			fileReader.readAsText(event.target.files[0]);
			document.body.removeChild(element);
		});
		document.body.appendChild(element);
		element.click();
	});
}



// DOWNLOAD


var _Debugger_download = F2(function(historyLength, json)
{
	return __Scheduler_nativeBinding(function(callback)
	{
		var fileName = 'history-' + historyLength + '.txt';
		var jsonString = JSON.stringify(json);
		var mime = 'text/plain;charset=utf-8';
		var done = __Scheduler_succeed(__Utils_Tuple0);

		// for IE10+
		if (navigator.msSaveBlob)
		{
			navigator.msSaveBlob(new Blob([jsonString], {type: mime}), fileName);
			return callback(done);
		}

		// for HTML5
		var element = document.createElement('a');
		element.setAttribute('href', 'data:' + mime + ',' + encodeURIComponent(jsonString));
		element.setAttribute('download', fileName);
		element.style.display = 'none';
		document.body.appendChild(element);
		element.click();
		document.body.removeChild(element);
		callback(done);
	});
});



// POPOUT CONTENT


function _Debugger_messageToString(value)
{
	switch (typeof value)
	{
		case 'boolean':
			return value ? 'True' : 'False';
		case 'number':
			return value + '';
		case 'string':
			return '"' + _Debugger_addSlashes(value, false) + '"';
	}
	if (value instanceof String)
	{
		return '\'' + _Debugger_addSlashes(value, true) + '\'';
	}
	if (typeof value !== 'object' || value === null || !('ctor' in value))
	{
		return '…';
	}

	var ctorStarter = value.ctor.substring(0, 5);
	if (ctorStarter === '_Tupl' || ctorStarter === '_Task')
	{
		return '…'
	}
	if (['_Array', '<decoder>', '_Process', '::', '[]', 'Set_elm_builtin', 'RBNode_elm_builtin', 'RBEmpty_elm_builtin'].indexOf(value.ctor) >= 0)
	{
		return '…';
	}

	var keys = Object.keys(value);
	switch (keys.length)
	{
		case 1:
			return value.ctor;
		case 2:
			return value.ctor + ' ' + _Debugger_messageToString(value._0);
		default:
			return value.ctor + ' … ' + _Debugger_messageToString(value[keys[keys.length - 1]]);
	}
}


function _Debugger_primitive(str)
{
	return { ctor: 'Primitive', _0: str };
}


function _Debugger_init(value)
{
	var type = typeof value;

	if (type === 'boolean')
	{
		return {
			ctor: 'Constructor',
			_0: __Maybe_Just(value ? 'True' : 'False'),
			_1: true,
			_2: __List_Nil
		};
	}

	if (type === 'number')
	{
		return _Debugger_primitive(value + '');
	}

	if (type === 'string')
	{
		return { ctor: 'S', _0: '"' + _Debugger_addSlashes(value, false) + '"' };
	}

	if (value instanceof String)
	{
		return { ctor: 'S', _0: "'" + _Debugger_addSlashes(value, true) + "'" };
	}

	if (value instanceof Date)
	{
		return _Debugger_primitive('<' + value.toString() + '>');
	}

	if (value === null)
	{
		return _Debugger_primitive('XXX');
	}

	if (type === 'object' && 'ctor' in value)
	{
		var ctor = value.ctor;

		if (ctor === '::' || ctor === '[]')
		{
			return {
				ctor: 'Sequence',
				_0: {ctor: 'ListSeq'},
				_1: true,
				_2: A2(__List_map, _Debugger_init, value)
			};
		}

		if (ctor === 'Set_elm_builtin')
		{
			return {
				ctor: 'Sequence',
				_0: {ctor: 'SetSeq'},
				_1: true,
				_2: A3(__Set_foldr, _Debugger_initCons, __List_Nil, value)
			};
		}

		if (ctor === 'RBNode_elm_builtin' || ctor == 'RBEmpty_elm_builtin')
		{
			return {
				ctor: 'Dictionary',
				_0: true,
				_1: A3(__Dict_foldr, _Debugger_initKeyValueCons, __List_Nil, value)
			};
		}

		if (ctor === '_Array')
		{
			return {
				ctor: 'Sequence',
				_0: {ctor: 'ArraySeq'},
				_1: true,
				_2: A3(__Array_foldr, _Debugger_initCons, __List_Nil, value)
			};
		}

		var ctorStarter = value.ctor.substring(0, 5);
		if (ctorStarter === '_Task')
		{
			return _Debugger_primitive('<task>');
		}

		if (ctor === '<decoder>')
		{
			return _Debugger_primitive(ctor);
		}

		if (ctor === '_Process')
		{
			return _Debugger_primitive('<process>');
		}

		var list = __List_Nil;
		for (var i in value)
		{
			if (i === 'ctor') continue;
			list = __List_Cons(_Debugger_init(value[i]), list);
		}
		return {
			ctor: 'Constructor',
			_0: ctorStarter === '_Tupl' ? __Maybe_Nothing : __Maybe_Just(ctor),
			_1: true,
			_2: __List_reverse(list)
		};
	}

	if (type === 'object')
	{
		var dict = __Dict_empty;
		for (var i in value)
		{
			dict = A3(__Dict_insert, i, _Debugger_init(value[i]), dict);
		}
		return { ctor: 'Record', _0: true, _1: dict };
	}

	return _Debugger_primitive('XXX');
}

var _Debugger_initCons = F2(function initConsHelp(value, list)
{
	return __List_Cons(_Debugger_init(value), list);
});

var _Debugger_initKeyValueCons = F3(function(key, value, list)
{
	return __List_Cons(
		__Utils_Tuple2(_Debugger_init(key), _Debugger_init(value)),
		list
	);
});

function _Debugger_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');
	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}



// BLOCK EVENTS


function _Debugger_wrapViewIn(appEventNode, overlayNode, viewIn)
{
	var ignorer = _Debugger_makeIgnorer(overlayNode);
	var blocking = 'Normal';
	var overflow;

	var normalTagger = appEventNode.tagger;
	var blockTagger = function() {};

	return function(model)
	{
		var tuple = viewIn(model);
		var newBlocking = tuple._0.ctor;
		appEventNode.tagger = newBlocking === 'Normal' ? normalTagger : blockTagger;
		if (blocking !== newBlocking)
		{
			_Debugger_traverse('removeEventListener', ignorer, blocking);
			_Debugger_traverse('addEventListener', ignorer, newBlocking);

			if (blocking === 'Normal')
			{
				overflow = document.body.style.overflow;
				document.body.style.overflow = 'hidden';
			}

			if (newBlocking === 'Normal')
			{
				document.body.style.overflow = overflow;
			}

			blocking = newBlocking;
		}
		return tuple._1;
	}
}

function _Debugger_traverse(verbEventListener, ignorer, blocking)
{
	switch(blocking)
	{
		case 'Normal':
			return;

		case 'Pause':
			return _Debugger_traverseHelp(verbEventListener, ignorer, _Debugger_mostEvents);

		case 'Message':
			return _Debugger_traverseHelp(verbEventListener, ignorer, _Debugger_allEvents);
	}
}

function _Debugger_traverseHelp(verbEventListener, handler, eventNames)
{
	for (var i = 0; i < eventNames.length; i++)
	{
		document.body[verbEventListener](eventNames[i], handler, true);
	}
}

function _Debugger_makeIgnorer(overlayNode)
{
	return function(event)
	{
		if (event.type === 'keydown' && event.metaKey && event.which === 82)
		{
			return;
		}

		var isScroll = event.type === 'scroll' || event.type === 'wheel';

		var node = event.target;
		while (node !== null)
		{
			if (node.className === 'elm-overlay-message-details' && isScroll)
			{
				return;
			}

			if (node === overlayNode && !isScroll)
			{
				return;
			}
			node = node.parentNode;
		}

		event.stopPropagation();
		event.preventDefault();
	}
}

var _Debugger_mostEvents = [
	'click', 'dblclick', 'mousemove',
	'mouseup', 'mousedown', 'mouseenter', 'mouseleave',
	'touchstart', 'touchend', 'touchcancel', 'touchmove',
	'pointerdown', 'pointerup', 'pointerover', 'pointerout',
	'pointerenter', 'pointerleave', 'pointermove', 'pointercancel',
	'dragstart', 'drag', 'dragend', 'dragenter', 'dragover', 'dragleave', 'drop',
	'keyup', 'keydown', 'keypress',
	'input', 'change',
	'focus', 'blur'
];

var _Debugger_allEvents = _Debugger_mostEvents.concat('wheel', 'scroll');
