hellobar.defineModule('elements',
  ['hellobar', 'base.sanitizing', 'base.preview'],
  function (hellobar, sanitizing, preview) {

    const configuration = hellobar.createModuleConfiguration({
      elementCSS: 'string'
    });

    let siteElementsOnPage = [];

    function createAndAddToPage(siteElementModel) {
      return addToPage(create(siteElementModel));
    }

    // TODO -> elements (name the method just 'create')
    // TODO it was createSiteElement previously
    // Returns a SiteElement object from a hash of data
    function create(data) {
      var siteElement;

      var whitelistedProperties = ['headline', 'caption', 'link_text', 'custom_html', 'custom_css', 'custom_js'];

      // Sanitize the data
      data = sanitizing.sanitize(data, whitelistedProperties);

      // TODO REFACTOR class instance creation
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

    // TODO -> elements
    // Adds the SiteElement to the page
    function addToPage(siteElement) {
      if (siteElement.use_question) {
        siteElement = questionifySiteElement(siteElement);
      }
      // Return if already added to the page
      if (typeof(siteElement.pageIndex) != 'undefined') {
        return;
      }

      // Set the page index so it can be referenced
      siteElement.pageIndex = siteElementsOnPage.length;

      // Helper for template that returns the Javascript for a reference
      // to this object
      // TODO REFACTOR remove HB usage
      siteElement.me = 'window.parent.HB.findSiteElementOnPageById(' + siteElement.id + ')';

      // skip adding to the page if it is already on the page
      if (siteElementsOnPage.indexOf(siteElement) !== -1)
        return;

      // skip adding to the page if it is already on the page (by ID)
      const elementOnPage = siteElementsOnPage.reduce(function (found, existingElement) {
        return found || existingElement.id === siteElement.id
      }, false);

      if (elementOnPage === true) {
        return;
      }

      siteElementsOnPage.push(siteElement);

      // If there is a #nohb in the has we don't render anything
      if (document.location.hash === '#nohb') {
        return;
      }
      siteElement.setCSS(configuration.elementCSS());
      siteElement.attach();
    }

    // TODO -> elements ?
    // TODO REFACTOR this has three usages (traffic_growth, site_element.es6 and also this file)
    function findSiteElementOnPageById(site_element_id) {
      var lookup = {};
      for (var i = 0, len = siteElementsOnPage.length; i < len; i++) {
        lookup[siteElementsOnPage[i].id] = siteElementsOnPage[i];
      }

      if (lookup[site_element_id] === undefined) {
        return null;
      } else {
        return lookup[site_element_id];
      }
    }

    // TODO this is used from editor only (application.mixin.preview.js)
    function removeAllSiteElements() {
      for (var i = 0; i < siteElementsOnPage.length; i++) {
        siteElementsOnPage[i].remove();
      }
      siteElementsOnPage = [];
    }

    // TODO -> elements
    // TODO used from bar.es6, site_element.es6, overridden in editor
    // Injects the specified element at the top of the body tag
    // or bottom if reverse is selected
    // TODO REFACTOR how to do overriding from editor here
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

    // TODO -> elements
    // Replaces the site element with the question variation.
    // Sets the displayAnswer callback to show the original element
    function questionifySiteElement(siteElement) {
      if (!siteElement.use_question || !siteElement.dataCopy) {
        return siteElement;
      }

      // Create a copy of the siteElement
      var originalSiteElement = siteElement;
      siteElement = siteElement.dataCopy;

      siteElement.questionified = true;

      // Set the template and headline
      // Remove the image from the question
      siteElement.template_name = siteElement.template_name.split('_')[0] + '_question';
      siteElement.headline = siteElement.question;
      siteElement.caption = null;
      siteElement.use_question = false;
      siteElement.image_url = null;

      // Create the new question site element
      siteElement = create(siteElement);

      // Set the callback.  When this is called, it sets the values on the original element
      // and displays it.
      siteElement.displayAnswer = function (choice) {
        if (choice === 1) {
          originalSiteElement.headline = siteElement.answer1response;
          originalSiteElement.caption = siteElement.answer1caption;
          originalSiteElement.link_text = siteElement.answer1link_text;
        } else {
          originalSiteElement.headline = siteElement.answer2response;
          originalSiteElement.caption = siteElement.answer2caption;
          originalSiteElement.link_text = siteElement.answer2link_text;
        }

        // Dont use the question, otherwise we end up in a loop.
        // Also, don't animate in since the element will already be on the screen
        // Also, don't record the view since it's already been recorded
        originalSiteElement.use_question = false;
        originalSiteElement.animated = false;
        originalSiteElement.dontRecordView = true;
        originalSiteElement.view_condition = 'immediately';

        // Remove the siteElement and show the original in non preview environments
        if (!preview.isActive()) {
          siteElement.remove();
          // also remove siteElement object from HB.siteElementsOnPage array
          siteElementsOnPage.splice(siteElementsOnPage.indexOf(siteElement), 1);
          addToPage(originalSiteElement);
        }
      };

      if (preview.isActive() && preview.getAnswerToDisplay()) {
        siteElement.displayAnswer(preview.getAnswerToDisplay());
        siteElement = originalSiteElement;
      }

      return siteElement;
    }

    return {
      createAndAddToPage,
      removeAllSiteElements
    };

  });
