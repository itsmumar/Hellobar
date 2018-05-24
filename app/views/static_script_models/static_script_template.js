window.hellobarSiteSettings = window.hellobarSiteSettings || $INJECT_DATA;

var bootstrap = function(src) {
  var d = document,
    head = d.head || d.getElementsByTagName("head")[0];

  script = d.createElement("script");
  script.async = 1;
  script.src = src;
  head.appendChild(script);
};

bootstrap($INJECT_MODULES);
