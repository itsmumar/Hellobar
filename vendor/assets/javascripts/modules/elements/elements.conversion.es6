hellobar.defineModule('elements.intents', [], function () {

  // TODO -> some tracking module ??? (elements.conversion??)
// Called when a conversion happens (e.g. link clicked, email form filled out)
  function converted(siteElement, callback) {
    var conversionKey = HB.getConversionKey(siteElement);
    var now = Math.round(new Date().getTime() / 1000);
    var conversionCount = (HB.getVisitorData(conversionKey) || 0 ) + 1;

    // Set the number of conversions for the visitor for this type of conversion
    HB.setVisitorData(conversionKey, conversionCount);
    // Record first time converted, unless already set for the visitor for this type of conversion
    HB.setVisitorData(conversionKey + '_f', now);
    // Record last time converted for the visitor for this type of conversion
    HB.setVisitorData(conversionKey + '_l', now);

    HB.setVisibilityControlCookie('success', siteElement);

    // Set the number of conversions for the specific site element
    HB.setSiteElementData(siteElement.id, 'nc', (HB.getSiteElementData(siteElement.id, 'nc') || 0) + 1);
    // Set the first time converted for the site element if not set
    if (!HB.getSiteElementData(siteElement.id, 'fc'))
      HB.setSiteElementData(siteElement.id, 'fc', now);
    // Set the last time converted for the site element to now
    HB.setSiteElementData(siteElement.id, 'lc', now);
    // Trigger the event
    HB.trigger('conversion', siteElement); // Old-style trigger
    HB.trigger('converted', siteElement); // Updated trigger
    // Send the data to the backend if this is the first conversion
    if (conversionCount === 1)
      HB.s('g', siteElement.id, {a: HB.getVisitorAttributes()}, callback);
    else if (typeof(callback) === typeof(Function))
      callback();
  }

  // TODO -> elements.conversion ???
  // Called when the siteElement is viewed
  function viewed(siteElement) {
    // Track number of views if not yet converted for this site element
    if (!HB.didConvert(siteElement))
      HB.s('v', siteElement.id, {a: HB.getVisitorAttributes()});

    // Record the number of views, first seen and last seen
    HB.setSiteElementData(siteElement.id, 'nv', (HB.getSiteElementData(siteElement.id, 'nv') || 0) + 1);
    var now = Math.round((new Date()).getTime() / 1000);
    if (!HB.getSiteElementData(siteElement.id, 'fv'))
      HB.setSiteElementData(siteElement.id, 'fv', now);
    HB.setSiteElementData(siteElement.id, 'lv', now);
    // Trigger siteElement shown event
    HB.trigger('siteElementShown', siteElement); // Old-style trigger
    HB.trigger('shown', siteElement); // New trigger
  }

  // TODO -> elements.conversion (should be inner)
  function getVisitorAttributes() {
    // Ignore first and last view timestamps and email and social conversions
    var ignoredAttributes = 'fv lv ec sc dt';
    // Ignore first and last converted timestamps and number of traffic conversions
    var ignoredAttributePattern = /(^ec.*_[fl]$)|(^sc.*_[fl]$)|(^l\-.+)/
    var attributes = {};
    // Remove ignored attributes
    for (var k in HB.cookies.visitor) {
      var value = HB.cookies.visitor[k];
      if ((typeof(value) === 'string' || typeof(value) === 'number' || typeof(value) === 'boolean') && ignoredAttributes.indexOf(k) === -1 && !k.match(ignoredAttributePattern)) {
        attributes[k.toLowerCase()] = (HB.cookies.visitor[k] + '').toLowerCase().substr(0, 150);
      }
    }
    return HB.serializeCookieValues(attributes);
  }

  // TODO -> elements.conversion (should be inner)
  // Returns true if the visitor did this conversion or not
  function didConvert(siteElement) {
    return HB.getVisitorData(HB.getConversionKey(siteElement));
  }

  // TODO -> some tracking module ??? (elements.conversion?)
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
        return 'l-' + HB.getShortestKeyForURL(siteElement.settings.url);
      // -------------------------------------------------------
      // IMPORTANT - if you add other conversion keys you need to
      // update the ignoredAttributePattern in getVisitorAttributes
    }
  }

  // TODO should be inner (used in getConversionKey)
  // Returns the shortest possible key for the given URL,
  // which may be a SHA1 hash of the url
  function getShortestKeyForURL(url) {
    // If the URL is a path already or it's on the same domain
    // strip to just the path
    if (url.indexOf('/') === 0 || HB.getNDomain(url) == HB.getNDomain(document.location)) {
      url = HB.n(url, true);
    } else {
      url = HB.n(url); // Get full URL
    }
    // If the URL is shorter than 40 chars just return it
    if (url.length > 40) {
      return HBCrypto.SHA1(url).toString();
    } else {
      return url;
      // Otherwise return a SHA1 hash of the URL
    }
  }

  // TODO (should be inner) - used in getShortestKeyForURL
  // Takes a URL and returns normalized domain (downcase and strip www)
  getNDomain: function (url) {
    if (!url) {
      return '';
    }
    url = url + '';
    if (url.indexOf('/') === 0) {
      return '';
    }
    return url.replace(/.*?\:\/\//, '').replace(/(.*?)\/.*/, '$1').replace(/www\./i, '').toLowerCase();
  }


  const module = {
    initialize: () => null
  };

  return module;

});

