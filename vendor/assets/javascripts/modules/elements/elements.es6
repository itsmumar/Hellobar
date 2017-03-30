hellobar.defineModule('elements',
  ['hellobar', 'base.sanitizing', 'base.preview',
    'elements.class', 'elements.class.bar', 'elements.class.slider'],
  function (hellobar, sanitizing, preview,
            SiteElement, BarElement, SliderElement) {

    const configuration = hellobar.createModuleConfiguration({
      elementCSS: 'string'
    });

    const elementClasses = {
      SiteElement,
      BarElement,
      SliderElement
    };

    let siteElementsOnPage = [];

    function createAndAddToPage(siteElementModel) {
      return addToPage(create(siteElementModel));
    }

    // TODO -> elements (name the method just 'create')
    // TODO it was createSiteElement previously
    // Returns a SiteElement object from a hash of data
    function create(data) {
      const whitelistedProperties = ['headline', 'caption', 'link_text', 'custom_html', 'custom_css', 'custom_js'];

      // Sanitize the data
      data = sanitizing.sanitize(data, whitelistedProperties);

      const elementClassName = data.type + 'Element';
      const elementClass = elementClasses[elementClassName] || SiteElement;
      const siteElement = new elementClass(data);

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
      siteElement.me = 'hellobar("elements").findById(' + siteElement.id + ')';

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
    // TODO it was findSiteElementOnPageById previously
    function findById(siteElementId) {
      var lookup = {};
      for (var i = 0, len = siteElementsOnPage.length; i < len; i++) {
        lookup[siteElementsOnPage[i].id] = siteElementsOnPage[i];
      }

      if (lookup[siteElementId] === undefined) {
        return null;
      } else {
        return lookup[siteElementId];
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

    // Grabs site elements from valid rules and displays them
    function showSiteElements() {
      const processSiteElements = (siteElements) => {
        for (var i = 0; i < siteElements.length; i++) {
          createAndAddToPage(siteElements[i]);
        }
      };
      var siteElements = [];
      // If a specific element has already been set, use it
      // Otherwise use the tradition apply rules method
      var siteElement = getFixedSiteElement();
      if (siteElement) {
        processSiteElements([siteElement]);
      } else {
        siteElements = HB.applyRules().then((siteElements) => processSiteElements(siteElements));
      }

    }

    // If window.HB_element_id is set, use that to find the site element
    // Will return null if HB_element_id is not set or no site element exists with that id
    function getFixedSiteElement() {
      var i, j;
      if (window.HB_element_id != null) {
        for (i = 0; i < HB.rules.length; i++) {
          var rule = HB.rules[i];
          for (j = 0; j < rule.siteElements.length; j++) {
            var siteElement = rule.siteElements[j];
            if (siteElement.wordpress_bar_id === window.HB_element_id)
              return siteElement;
          }
        }
      }
      return null;
    }


    return {
      configuration: () => configuration,
      initialize() {
        showSiteElements();
      },
      createAndAddToPage,
      removeAllSiteElements,
      findById
    };

  });
