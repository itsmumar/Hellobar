window.hbSiteSettings = window.hbSiteSettings || $INJECT_DATA;

window.hbBootstrap = window.hbBootstrap || function (src) {
    var d = document,
        head = d.head || d.getElementsByTagName("head")[0];

    script = d.createElement("script");
    script.async = 1;
    script.src = src;
    head.appendChild(script);
  };

hbBootstrap($INJECT_MODULES);
