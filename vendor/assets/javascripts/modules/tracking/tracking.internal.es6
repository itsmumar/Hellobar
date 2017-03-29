hellobar.defineModule('tracking.internal',
  ['hellobar', 'base.site', 'base.storage', 'base.preview', 'base.format'],
  function (hellobar, site, storage, preview, format) {

    const configuration = hellobar.createModuleConfiguration({
      backendHost: 'string',
      siteWriteKey: 'string'
    });

    // TODO -> tracking.internal
    // Sends data to the tracking server (e.g. which siteElements viewed, if a rule was performed, etc)
    function send(path, itemID, params, callback) {
      if (isTrackingDisabled()) {
        callback && callback();
        return;
      }
      // Build the URL
      var url = '/' + path + '/' + obfID(site.siteId());
      if (itemID) {
        url += '/' + obfID(itemID);
      }
      var now = Math.round(new Date().getTime() / 1000);

      params['t'] = now; // Timestamp
      params['v'] = visitorUUID(); // visitor UUID
      params['f'] = 'i'; // Make sure we return an image

      // Sign the URL
      params['s'] = signature(configuration.siteWriteKey(), url, params);

      // Add the query string
      url += '?' + paramsToString(params);

      var img = document.createElement('img');
      img.style.display = 'none';
      if (callback) {
        // Make sure you only call the callback once
        var issuedCallback = false;
        var issueCallback = function () {
          if (!issuedCallback) {
            callback();
          }
          issuedCallback = true;
        };
        // Call the callback within a set period of time in case the image
        // does not load
        setTimeout(issueCallback, 750);
        img.onload = issueCallback;
      }
      img.src = hi(url);
    }

    function disableTrackingIfRequired(queryString) {
      if (queryString.match(/hb_ignore/i)) {
        var bool = !!queryString.match(/hb_ignore=true/i);
        storage.setValue('disableTracking', bool, 5 * 365);
      }
    }

    function isTrackingDisabled() {
      return preview.isActive() || format.asBool(storage.getValue('disableTracking'));
    }

// TODO -> tracking.hb (make it inner function)
// Returns the URL for the backend server (e.g. "hi.hellobar.com").
    function hi(url) {
      return (document.location.protocol === 'https:' ? 'https' : 'http') + '://' + configuration.backendHost() + url;
    }

    // TODO this should be inner for s (tracking.hb)
    function paramsToString(params) {
      var pairs = [];
      for (var k in params) {
        if (typeof(params[k]) != 'function') {
          pairs.push(encodeURIComponent(k) + '=' + encodeURIComponent(params[k]));
        }
      }
      return pairs.join('&');
    }

    // TODO this is inner of 's' (tracking)
    // Takes an input ID and returns an obfuscated ID
    // This is the required format for IDs for hi.hellobar.com
    function obfID(number) {
      var SEP = '-';
      var ZERO_ENCODE = '_';
      var ENCODE = 'S6pjZ9FbD8RmIvT3rfzVWAloJKMqg7CcGe1OHULNuEkiQByns5d4Y0PhXw2xta';
      var id = number + '';
      var outputs = [];
      var initialInputs = [id.slice(0, 3), id.slice(3, 6), id.slice(6, 9)];
      var inputs = [];
      var i;
      for (i = 0; i < initialInputs.length; i++) {
        if (initialInputs[i])
          inputs.push(initialInputs[i]);
      }
      for (i = 0; i < inputs.length; i++) {
        var output = '';
        var chars = inputs[i].split('');
        for (var c = 0; c < chars.length; c++) {
          if (chars[c] != '0')
            break;
          output += ZERO_ENCODE;
        }
        var inputInt = parseInt(inputs[i], 10);
        if (inputInt != 0) {
          while (1) {
            var val;
            if (inputInt > ENCODE.length)
              val = Math.floor((Math.random() * ENCODE.length) + 1);
            else
              val = Math.floor((Math.random() * inputInt) + 1);
            output += ENCODE[val - 1];
            inputInt -= val;
            if (inputInt <= 0)
              break;
          }
        }
        outputs.push(output);
      }
      return outputs.join(SEP);
    }

    // TODO this is inner of 's' (tracking)
    // Signs a given path and params with the provided key
    function signature(key, path, params) {

      // NOTE: This is using the unencoded values for the params because
      // we don't want to get different signatures if one library encodes a
      // space as "+" and another as "%20" for example
      var sortedParamPairs = [];
      for (var k in params) {
        if (typeof(params[k]) != 'function' && k != 's') {
          sortedParamPairs.push(k + '=' + params[k]);
        }
      }
      sortedParamPairs.sort();

      return HBCrypto.HmacSHA512(path + '?' + sortedParamPairs.join('|'), key).toString();

    }

    // Returns the visitor's unique ID which should be a random value
    function visitorUUID() {
      var uuid;
      // Check if we have a cookie
      if (uuid = storage.getValue('hbuid')) {
        return uuid; // If so return that
      }
      // Otherwise generate a new value
      var d = new Date().getTime();
      uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = (d + Math.random() * 16) % 16 | 0;
        d = Math.floor(d / 16);
        return (c == 'x' ? r : (r & 0x7 | 0x8)).toString(16);
      });
      // Set it in the cookie
      storage.setValue('hbuid', uuid, 5 * 365);

      // Return it
      return uuid;
    }

    return {
      configuration: () => configuration,
      initialize () {
        disableTrackingIfRequired(location.search);
      },
      send
    };

  });

