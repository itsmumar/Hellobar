hellobar.defineModule('base.selfcheck',
  ['hellobar', 'base.preview', 'base.format', 'base.site'],
  function (hellobar, preview, format, site) {

    function getLocation() {
      return window.location;
    }

    function isIpAddress(ipaddress) {
      if (/^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(ipaddress))
        return true;
      else
        return false;
    }

    return {
      scriptIsInstalledProperly() {
        // return true when viewing in preview pane
        if (preview.isActive()) {
          return true;
        }

        var hostname = getLocation().hostname;

        if (isIpAddress(hostname) || hostname === 'localhost')
          return true;

        // If the site is the generic one used for force converts
        // we still want to show the bar
        return site.siteUrl() === 'http://mysite.com' ||
          format.normalizeUrl(hostname) === format.normalizeUrl(site.siteUrl());
      }

    };

  });
