var HB_HelloBar = function(a, b) {
	var n = navigator.userAgent.toLowerCase();
	var o = {
		version: (n.match(/.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/) || [])[1],
		safari: /webkit/.test(n),
		opera: /opera/.test(n),
		msie: (/msie/.test(n)) && (!/opera/.test(n)),
		mozilla: (/mozilla/.test(n)) && (!/(compatible|webkit)/.test(n))
	};
	var p = false;
	var q = false;
	var r = [];
	if (document.addEventListener) {
		DOMContentLoaded = function() {
			document.removeEventListener("DOMContentLoaded", DOMContentLoaded, false);
			ready()
		}
	} else if (document.attachEvent) {
		DOMContentLoaded = function() {
			if (document.readyState === "complete") {
				document.detachEvent("onreadystatechange", DOMContentLoaded);
				ready()
			}
		}
	}
	function ready() {
		if (!q) {
			if (!document.body) {
				return setTimeout(ready, 13)
			}
			q = true;
			if (r) {
				var a, i = 0;
				while ((a = r[i++])) {
					a.call(document, [])
				}
				r = null
			}
			ready()
		}
	}
	function bindReady() {
		if (p) {
			return
		}
		p = true;
		if (document.readyState === "complete") {
			return ready()
		}
		if (document.addEventListener) {
			document.addEventListener("DOMContentLoaded", DOMContentLoaded, false);
			window.addEventListener("load", ready, false)
		} else if (document.attachEvent) {
			document.attachEvent("onreadystatechange", DOMContentLoaded);
			window.attachEvent("onload", ready);
			var a = false;
			try {
				a = window.frameElement == null
			} catch (e) {}
			if (document.documentElement.doScroll && a) {
				doScrollCheck()
			}
		}
	}
	function doScrollCheck() {
		if (q) {
			return
		}
		try {
			document.documentElement.doScroll("left")
		} catch (error) {
			setTimeout(doScrollCheck, 1);
			return
		}
		ready()
	}
	function setCookie(a, b, c) {
		var d = false;
		var e = new Date()
			, days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
			, months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Nov', 'Dec'];
		var D = new Date(e.getTime() + (365 * 86400000));
		if (typeof (c) != 'undefined') {
			if (c === true) {
				D = new Date(e.getTime() - (1 * 86400000))
			}
			if (c == 'this_session') {
				d = true
			}
		}
		var f = days[D.getUTCDay()] + ", " + D.getUTCDate() + " " + months[D.getUTCMonth()] + " " + D.getUTCFullYear() + " " + D.getUTCHours() + ":" + D.getUTCMinutes() + ":" + D.getUTCSeconds() + " UTC";
		if (d) {
			document.cookie = a + "=" + b + "; path=/"
		} else {
			document.cookie = a + "=" + b + "; expires=" + f + "; path=/"
		}
	}
	this.ready = function(a) {
		bindReady();
		if (q) {
			a.call(document, [])
		} else if (r) {
			r.push(a)
		}
		return this
	}
	;
	this.ready(function() {
		var f = document.location.protocol + '//old.hellobar.com/hellobar-' + a + '-' + b;
		var g = document.cookie.match(/hellobar_current\=([0-9]+);?/);
		if (g) {
			var h = g[1];
			var i = new RegExp("hellobar_" + h + "_variation\=([0-9]+);?");
			var j = document.cookie.match(i);
			if (j) {
				f += "-" + j[1]
			}
			var k = document.cookie.match(/hellobar_([0-9]+)_(variation|hide|shown)/g);
			if (k) {
				for (var c = 0; c < k.length; c++) {
					var l = new RegExp("hellobar_" + h + "_(variation|hide|shown)");
					var m = k[c];
					if (!m.match(l)) {
						setCookie(m, 0, true)
					}
				}
			}
		}
		f += '.js';
		var d = document.getElementsByTagName('HEAD')[0];
		var e = document.createElement('SCRIPT');
		e.type = 'text/javascript';
		e.src = f;
		d.appendChild(e)
	})
};

var HelloBar=function(a, b) {
  window.HB_element_id = b;
  var url = "//my.hellobar.com/" + a + "_" + b + ".js"
  var ele = document.createElement("script");
  ele.setAttribute("src", url);
  ele.onerror = function() {
    HB_HelloBar(a, b);
  };
  var f = function(){
    if ( document && document.body && document.body.appendChild )
      document.body.appendChild(ele);
    else
      setTimeout(f, 50);
  }
  f();
};
