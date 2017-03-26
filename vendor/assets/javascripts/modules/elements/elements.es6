hellobar.defineModule('elements', [], function () {

  // TODO -> elements (name the method just 'create')
  // Returns a SiteElement object from a hash of data
  function createSiteElement(data) {
    var siteElement;

    var whitelistedProperties = ['headline', 'caption', 'link_text', 'custom_html', 'custom_css', 'custom_js'];

    // TODO do we need to sanitize blocks property?
    // Sanitize the data
    data = HB.sanitize(data, whitelistedProperties);
    // Make a copy of the siteElement
    var fn = window.HB[data.type + 'Element'];
    if (typeof fn === 'function') {
      siteElement = new window.HB[data.type + 'Element'](data);
    } else {
      siteElement = new HB.SiteElement(data);
    }

    siteElement.dataCopy = data;
    return siteElement;
  }

  // TODO -> elements (join with createSiteElement?)
  // Adds the SiteElement to the page
  function addToPage(siteElement) {
    if (siteElement.use_question) {
      siteElement = HB.questionifySiteElement(siteElement);
    }
    // Return if already added to the page
    if (typeof(siteElement.pageIndex) != 'undefined')
      return;
    // Set the page index so it can be referenced
    siteElement.pageIndex = HB.siteElementsOnPage.length;

    // Helper for template that returns the Javascript for a reference
    // to this object
    siteElement.me = 'window.parent.HB.findSiteElementOnPageById(' + siteElement.id + ')';

    // skip adding to the page if it is already on the page
    if (HB.siteElementsOnPage.indexOf(siteElement) !== -1)
      return;

    // skip adding to the page if it is already on the page (by ID)
    elementOnPage = HB.siteElementsOnPage.reduce(function (found, existingElement) {
      return found || existingElement.id === siteElement.id
    }, false);

    if (elementOnPage === true)
      return;

    HB.siteElementsOnPage.push(siteElement);

    // If there is a #nohb in the has we don't render anything
    if (document.location.hash === '#nohb')
      return;
    siteElement.attach();
  }

  // TODO -> elements ?
  // TODO this has three usages (traffic_growth, site_element.es6 and also this file)
  function findSiteElementOnPageById(site_element_id) {
    var lookup = {};
    for (var i = 0, len = HB.siteElementsOnPage.length; i < len; i++) {
      lookup[HB.siteElementsOnPage[i].id] = HB.siteElementsOnPage[i];
    }

    if (lookup[site_element_id] === undefined) {
      return null;
    } else {
      return lookup[site_element_id];
    }
  }

  // TODO this is used from editor only (application.mixin.preview.js)
  function removeAllSiteElements() {
    for (var i = 0; i < HB.siteElementsOnPage.length; i++) {
      HB.siteElementsOnPage[i].remove();
    }
    HB.siteElementsOnPage = [];
  }

  // TODO -> elements
  // TODO used from bar.es6, site_element.es6, overridden in editor
  // Injects the specified element at the top of the body tag
  // or bottom if reverse is selected
  function injectAtTop(element, reverse) {
    reverse = typeof reverse !== 'undefined' ? reverse : false;

    if (!reverse && document.body.children.length > 0)
      document.body.insertBefore(element, document.body.children[0]);
    else
      document.body.appendChild(element);
  }

  // TODO -> elements
  function hideElement(element) {
    if (element == null) {
      return
    } // do nothing
    if (element.length == undefined) {
      element.style.display = 'none';
    } else {
      for (var i = 0; i < element.length; ++i) {
        element[i].style.display = 'none';
      }
    }
  }

  // TODO -> elements
  function showElement(element, display) {
    if (element == null) {
      return
    } // do nothing
    if (typeof display === 'undefined') {
      display = 'inline';
    }
    if (element.length == undefined) {
      element.style.display = display;
    } else {
      for (var i = 0; i < element.length; ++i) {
        element[i].style.display = display;
      }
    }
  }

  const module = {
    initialize: () => null
  };

  return module;

});
