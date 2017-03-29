hellobar.defineModule('base.visitor',
  ['base.format', 'base.timezone', 'base.environment', 'base.storage', 'base.serialization', 'base.site'],
  function (format, timezone, environment, storage, serialization, site) {

    // Visitor data cache
    let visitor = {};

    // TODO -> ??? (this is called during script initialization)
    // This just sets the default segments/tracking data for the visitor
    // (such as when the suer visited, referrer, etc)
    function setDefaultSegments() {
      var nowDate = new Date();
      var now = Math.round(nowDate.getTime() / 1000);
      var hour = 60 * 60;
      var day = 24 * hour;
      var newSession = 0;

      // Track first visit and most recent visit and time since
      // last visit
      if (!getVisitorData('fv'))
        setVisitorData('fv', now);
      // Get the previous visit
      var previousVisit = getVisitorData('lv');

      // Set the time since the last visit as the number
      // of days
      if (previousVisit)
        setVisitorData('ls', Math.round((now - previousVisit) / day));
      if (((now - previousVisit) / hour) > 1) {
        newSession = 1;
      }

      setVisitorData('lv', now);

      // Set the life of the visitor in number of days
      setVisitorData('lf', Math.round((now - getVisitorData('fv')) / day));

      // Track number of visitor visits
      setVisitorData('nv', (getVisitorData('nv') || 0) + 1);

      // Track number of visitor sessions
      setVisitorData('ns', (getVisitorData('ns') || 0) + newSession);

      // Check for UTM params
      var params = paramsFromString(document.location);

      setVisitorData('ad_so', params['utm_source'], true);
      setVisitorData('ad_ca', params['utm_campaign'], true);
      setVisitorData('ad_me', params['utm_medium'], true);
      setVisitorData('ad_co', params['utm_content'], true);
      setVisitorData('ad_te', params['utm_term'], true);

      setVisitorData('pq', params, true);

      // Set referrer if it is from a different domain (don't count internal referrers)
      if (document.referrer) {
        var tld = getTLD().toLowerCase();
        // Check to ensure that the tld is not present in the
        var referrer = (document.referrer + '').replace(/.*?\:\/\//, '').replace(/www\./i, '').toLowerCase().substr(0, 150);
        var referrerDomain = referrer.replace(/(.*?)\/.*/, '$1');
        if (referrerDomain.indexOf(tld) == -1) {
          // This is an external referrer
          // Set the original referrer if not set
          if (!getVisitorData('or'))
            setVisitorData('or', referrer);
          // Set the full current referrer
          setVisitorData('rf', referrer);
          // Set the referrer domain
          setVisitorData('rd', referrerDomain);

          // Check for search terms
          var referrerParams = paramsFromString(document.referer);
          // Check for search terms
          setVisitorData('st', referrerParams['query'] || referrerParams['q'] || referrerParams['search'], true);
        }

        // Always set the previous page to the referrer
        setVisitorData('pp', referrer);
      } else {
        // There is no referrer so set the 'rf' and 'rd' segments to blank
        setVisitorData('rf', '');
        setVisitorData('rd', '');
        setVisitorData('pp', '');
      }
      // Set the page URL
      setVisitorData('pu', format.normalizeUrl(document.location + '', false));

      // Set the page path
      setVisitorData('pup', format.normalizeUrl(document.location.pathname, true));

      // Set the date
      setVisitorData('dt', ymd(timezone.nowInTimezone()));
      // Detect the device
      setVisitorData('dv', environment.device());
    }


    // TODO this should be inner for setDefaultSegments
    function paramsFromString(url) {
      var params = {};
      if (!url)
        return params;
      url += ''; // cast to string
      var query = url.indexOf('?') == -1 ? url : url.split('?')[1];
      if (!query)
        return params;
      var pairs = query.split('&');
      for (var i = 0; i < pairs.length; i++) {
        var key, value;
        var components = pairs[i].split('=');
        components[1] || (components[1] = ''); // default the key to an empty string

        // handle ASCII encoding
        var utf8bytes = unescape(encodeURIComponent(components[0]));
        var key = decodeURIComponent(escape(utf8bytes));

        var utf8bytes = unescape(encodeURIComponent(components[1]));
        var value = decodeURIComponent(escape(utf8bytes));

        params[key] = value;
      }
      return params;
    }

    // TODO this should be inner for setDefaultSegments
    // This code returns the root domain of the current site so "www.yahoo.co.jp" will return "yahoo.co.jp" and "blog.kissmetrics.com
    // will return kissmetrics.com. It does so by setting a cookie on each "part" until successful (first tries ".jp" then ".co.jp"
    // then "yahoo.co.jp"
    function getTLD() {
      var i, h,
        wc = 'tld=ck',
        hostname = document.location.hostname.split('.');
      for (i = hostname.length - 1; i >= 0; i--) {
        h = hostname.slice(i).join('.');
        document.cookie = wc + ';domain=.' + h + ';';
        if (document.cookie.indexOf(wc) > -1) {
          document.cookie = wc.split('=')[0] + '=;domain=.' + h + ';expires=Thu, 01 Jan 1970 00:00:01 GMT;';
          return h;
        }
      }
      return document.location.hostname;
    }

    // TODO this is inner of setDefaultSegments
    function ymd(date) {
      if (typeof date === 'undefined') date = new Date();
      var m = date.getMonth() + 1;
      return date.getFullYear() + '-' + zeropad(m) + '-' + zeropad(date.getDate());
    }

    // TODO this is inner of setDefaultSegments
    // Copied from zeropad.jquery.js
    function zeropad(string, length) {
      // default to 2
      string = string.toString();
      if (typeof length === 'undefined' && string.length == 1) length = 2;
      length = length || string.length;
      return string.length >= length ? string : zeropad('0' + string, length);
    }

    // TODO -> base.visitor
    // Gets the visitor attribute specified by the key or returns null
    function getVisitorData(key) {

      // TODO REFACTOR is key is empty return whole data object
      if (!key) {
        return null;
      }

      if (key.indexOf('gl_') !== -1) {
        // TODO can we move geolocation dependency to another place?
        return hellobar('geolocation').getGeolocationData(key, function (data, isCached) {
          if (isCached === false) {
            // TODO ??? move this to another place
            HB.loadCookies();
            HB.showSiteElements();
          }
        });
      }
      else {
        return visitor[key];
      }
    }

    function setVisitorData(key, value, skipEmptyValue) {
      if (skipEmptyValue && !value) // This allows us to only conditionally set values
        return;
      visitor[key] = value;
      saveVisitorData();
    }

    function saveVisitorData() {
      storage.setValue('hbv_' + site.siteId(), serialization.serialize(visitor), 365 * 5);
    }

    function loadVisitorData() {
      visitor = serialization.deserialize(storage.getValue('hbv_' + site.siteId()));
    }

    function setConverted(conversionKey) {
      var now = Math.round(new Date().getTime() / 1000);
      var conversionCount = (getVisitorData(conversionKey) || 0 ) + 1;

      // Set the number of conversions for the visitor for this type of conversion
      setVisitorData(conversionKey, conversionCount);
      // Record first time converted, unless already set for the visitor for this type of conversion
      setVisitorData(conversionKey + '_f', now);
      // Record last time converted for the visitor for this type of conversion
      setVisitorData(conversionKey + '_l', now);
    }

    return {
      initialize() {
        loadVisitorData();
        setDefaultSegments();
      },
      setConverted,
      getData(key) {
        return getVisitorData();
      }
    };

  });
