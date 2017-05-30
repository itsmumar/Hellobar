hellobar.defineModule('elements.conversion',
  ['base.format', 'base.serialization', 'base.bus', 'lib.crypto',
    'visitor', 'elements.data', 'elements.visibility', 'tracking.internal', 'tracking.external'],
  function (format, serialization, bus, crypto,
            visitor, elementsData, elementsVisibility, trackingInternal, trackingExternal) {

    // Called when a conversion happens (e.g. link clicked, email form filled out)
    function converted(siteElement, callback) {
      const siteElementModel = siteElement.model ? siteElement.model() : siteElement;
      const id = siteElementModel.id;
      const gaEventType = () => siteElementModel.subtype + '_conversion';
      var conversionKey = getConversionKey(siteElementModel);
      var now = Math.round(new Date().getTime() / 1000);
      var conversionCount = (visitor.getData(conversionKey) || 0 ) + 1;

      visitor.setConverted(conversionKey);

      elementsVisibility.setVisibilityControlCookie('success', siteElementModel);

      // Set the number of conversions for the specific site element
      elementsData.setData(id, 'nc', (elementsData.getData(id, 'nc') || 0) + 1);
      // Set the first time converted for the site element if not set
      if (!elementsData.getData(id, 'fc'))
        elementsData.setData(id, 'fc', now);
      // Set the last time converted for the site element to now
      elementsData.setData(id, 'lc', now);
      // Trigger the event
      bus.trigger('hellobar.elements.converted', siteElementModel);
      // Send the data to the backend if this is the first conversion
      if (conversionCount === 1) {
        trackingInternal.send('g', id, {a: getVisitorAttributes()}, callback);
        trackingExternal.send(gaEventType(), id);
      } else if (typeof(callback) === typeof(Function)) {
        callback();
      }
    }

    // Called when the siteElement is viewed
    function viewed(siteElement) {
      const siteElementModel = siteElement.model ? siteElement.model() : siteElement;
      const id = siteElementModel.id;

      // Track number of views if not yet converted for this site element
      if (!didConvert(siteElementModel)) {
        trackingInternal.send('v', id, {a: getVisitorAttributes()});
        trackingExternal.send('view', id);
      }

      // Record the number of views, first seen and last seen
      elementsData.setData(id, 'nv', (elementsData.getData(id, 'nv') || 0) + 1);
      var now = Math.round((new Date()).getTime() / 1000);
      if (!elementsData.getData(id, 'fv'))
        elementsData.setData(id, 'fv', now);
      elementsData.setData(id, 'lv', now);

      // Trigger event
      bus.trigger('hellobar.elements.viewed', siteElementModel);
    }

    function getVisitorAttributes() {
      // Ignore first/last view timestamps, email/social conversions, date of visit
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
    function didConvert(siteElementModel) {
      conversionKey = getConversionKey(siteElementModel);

      return conversionKey && visitor.getData(getConversionKey(siteElementModel));
    }

    // Returns the conversion key used in the cookies to determine if this
    // conversion has already happened or not
    function getConversionKey(siteElementModel) {
      if (siteElementModel.type == 'ContentUpgrade') {
        return 'ec';
      }

      switch (siteElementModel.subtype) {
        case 'email':
          return 'ec';
        case 'social':
          return 'sc';
        case 'traffic':
          // Need to make sure this is unique per URL
          // getShortestKey returns either the raw URL or
          // a SHA1 hash of the URL - whichever is shorter
          return 'l-' + getShortestKeyForURL(siteElementModel.settings.url);
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

