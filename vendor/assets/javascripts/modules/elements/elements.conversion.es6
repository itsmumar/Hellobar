hellobar.defineModule('elements.conversion',
  ['base.format', 'base.serialization', 'base.bus', 'lib.crypto',
    'visitor', 'elements.data', 'elements.visibility', 'tracking.internal'],
  function (format, serialization, bus, crypto,
            visitor, elementsData, elementsVisibility, trackingInternal) {

    // Called when a conversion happens (e.g. link clicked, email form filled out)
    function converted(siteElement, callback) {
      var conversionKey = getConversionKey(siteElement);
      var now = Math.round(new Date().getTime() / 1000);
      var conversionCount = (visitor.getData(conversionKey) || 0 ) + 1;

      visitor.setConverted(conversionKey);

      elementsVisibility.setVisibilityControlCookie('success', siteElement);

      // Set the number of conversions for the specific site element
      elementsData.setData(siteElement.id, 'nc', (elementsData.getData(siteElement.id, 'nc') || 0) + 1);
      // Set the first time converted for the site element if not set
      if (!elementsData.getData(siteElement.id, 'fc'))
        elementsData.setData(siteElement.id, 'fc', now);
      // Set the last time converted for the site element to now
      elementsData.setData(siteElement.id, 'lc', now);
      // Trigger the event
      bus.trigger('hellobar.elements.converted', siteElement);
      // Send the data to the backend if this is the first conversion
      if (conversionCount === 1) {
        trackingInternal.send('g', siteElement.id, {a: getVisitorAttributes()}, callback);
      } else if (typeof(callback) === typeof(Function)) {
        callback();
      }

    }

    // Called when the siteElement is viewed
    function viewed(siteElement) {
      // Track number of views if not yet converted for this site element
      if (!didConvert(siteElement))
        trackingInternal.send('v', siteElement.id, {a: getVisitorAttributes()});

      // Record the number of views, first seen and last seen
      elementsData.setData(siteElement.id, 'nv', (elementsData.getData(siteElement.id, 'nv') || 0) + 1);
      var now = Math.round((new Date()).getTime() / 1000);
      if (!elementsData.getData(siteElement.id, 'fv'))
        elementsData.setData(siteElement.id, 'fv', now);
      elementsData.setData(siteElement.id, 'lv', now);
      // Trigger event
      bus.trigger('hellobar.elements.viewed', siteElement);
    }

    function getVisitorAttributes() {
      // Ignore first and last view timestamps and email and social conversions
      var ignoredAttributes = 'fv lv ec sc dt';
      // Ignore first and last converted timestamps and number of traffic conversions
      var ignoredAttributePattern = /(^ec.*_[fl]$)|(^sc.*_[fl]$)|(^l\-.+)/;
      var attributes = {};
      // Remove ignored attributes
      const visitorData = visitor.getData();
      for (var k in visitorData) {
        var value = visitorData[k];
        if ((typeof(value) === 'string' || typeof(value) === 'number' || typeof(value) === 'boolean') && ignoredAttributes.indexOf(k) === -1 && !k.match(ignoredAttributePattern)) {
          attributes[k.toLowerCase()] = (visitorData[k] + '').toLowerCase().substr(0, 150);
        }
      }
      return serialization.serialize(attributes);
    }

    // Returns true if the visitor did this conversion or not
    function didConvert(siteElement) {
      return visitor.getData(getConversionKey(siteElement));
    }

    // Returns the conversion key used in the cookies to determine if this
    // conversion has already happened or not
    function getConversionKey(siteElement) {
      switch (siteElement.subtype) {
        case 'email':
          return 'ec';
        case 'social':
          return 'sc';
        case 'traffic':
          // Need to make sure this is unique per URL
          // getShortestKey returns either the raw URL or
          // a SHA1 hash of the URL - whichever is shorter
          return 'l-' + getShortestKeyForURL(siteElement.settings.url);
        // -------------------------------------------------------
        // IMPORTANT - if you add other conversion keys you need to
        // update the ignoredAttributePattern in getVisitorAttributes
      }
    }

    // Returns the shortest possible key for the given URL,
    // which may be a SHA1 hash of the url
    function getShortestKeyForURL(url) {
      // If the URL is a path already or it's on the same domain
      // strip to just the path
      if (url.indexOf('/') === 0 || getNDomain(url) == getNDomain(document.location)) {
        url = format.normalizeUrl(url, true);
      } else {
        url = format.normalizeUrl(url); // Get full URL
      }
      // If the URL is shorter than 40 chars just return it
      if (url.length > 40) {
        return crypto.SHA1(url).toString();
      } else {
        return url;
        // Otherwise return a SHA1 hash of the URL
      }
    }

    // Takes a URL and returns normalized domain (downcase and strip www)
    function getNDomain(url) {
      if (!url) {
        return '';
      }
      url = url + '';
      if (url.indexOf('/') === 0) {
        return '';
      }
      return url.replace(/.*?\:\/\//, '').replace(/(.*?)\/.*/, '$1').replace(/www\./i, '').toLowerCase();
    }

    // Records the rule being formed when the visitor clicks the specified element
    function trackClick(domElement, siteElement) {
      var url = domElement.href;
      converted(siteElement, function () {
        if (domElement.target != '_blank') document.location = url;
      });
    }


    return {
      converted,
      viewed,
      trackClick
    };

  });

