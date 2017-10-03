hellobar.defineModule('rules',
  ['base.deferred', 'elements.visibility', 'elements.relevance', 'rules.resolving'],
  function (deferred, elementsVisibility, elementsRelevance, ruleResolving) {

    let rules = [];

    const configuration = {
      // Adds a rule to the list of rules.
      //  matchType: is either 'any' or 'all' - refers to the conditions
      //  conditions: serialized array of conditions for the rule to be true
      //  siteElements: serialized array of siteElements if the rule is true
      addRule(matchType, conditions, siteElements) {
        // First check to see if siteElements is an array, and make it one if it is not
        if (Object.prototype.toString.call(siteElements) !== '[object Array]') {
          siteElements = [siteElements];
        }

        // Create the rule
        var rule = {matchType: matchType, conditions: conditions, siteElements: siteElements};
        rules.push(rule);
        // Set the rule on all of the siteElements
        for (var i = 0; i < siteElements.length; i++) {
          siteElements[i].rule = rule;
        }
      }
    };

    function resolveRules() {
      const rulePromises = rules.map((rule) => {
        if (rule.siteElements.length > 0) {
          const ruleResult = ruleResolving.resolve(rule);
          return deferred.wrap(ruleResult);
        }
        return deferred.constant({ rule, ruleActive: false });
      });

      return deferred.all(rulePromises);
    }

    function getVisibilityGroup(siteElement) {
      let visibilityGroup = siteElement.type;

      // For showing multiple elements at the same time a modal and a takeover are the same thing
      if (visibilityGroup === 'Modal' || visibilityGroup === 'Takeover')
        visibilityGroup = 'Modal/Takeover';

      return visibilityGroup;
    }

    function groupSiteElements(activeRules) {
      let visibilityGroups = {};

      activeRules.forEach(rule => {
        rule.siteElements.forEach((siteElement) => {
          const visibilityGroup = getVisibilityGroup(siteElement);

          if (!visibilityGroups[visibilityGroup]) {
            visibilityGroups[visibilityGroup] = [];
          }

          visibilityGroups[visibilityGroup].push(siteElement);
        });
      });

      return visibilityGroups;
    }

    function selectBestElementsForEachGroup(ruleResults) {
      const activeRules = ruleResults.
        filter(result => result.ruleActive).
        map(result => result.rule);

      const visibilityGroups = groupSiteElements(activeRules);

      // Now we have all elements that can be shown based on the rules
      // broken up into visibility groups
      // The next step is to pick one per visibility group
      let siteElements = [];

      // We need to specify the order that elements appear in. Whichever is first
      // in the array is on top
      const visibilityOrder = ['Modal/Takeover', 'Alert', 'Slider', 'Bar'];

      for (i = 0; i < visibilityOrder.length; i++) {
        let visibilityGroup = visibilityOrder[i];
        let visibleElements = visibilityGroups[visibilityGroup];

        if (visibleElements) {
          siteElement = elementsRelevance.getBestElement(visibleElements);

          if (siteElement && elementsVisibility.shouldShowElement(siteElement)) {
            siteElements.push(siteElement);
          }
        }
      }

      return siteElements;
    }

    // If window.HB_element_id is set, use that to find the site element
    // Will return null if HB_element_id is not set or no site element exists with that id
    function getFixedSiteElement() {
      var i, j;
      if (window.HB_element_id != null) {
        for (i = 0; i < rules.length; i++) {
          var rule = rules[i];
          for (j = 0; j < rule.siteElements.length; j++) {
            var siteElement = rule.siteElements[j];
            if (siteElement.wordpress_bar_id === window.HB_element_id)
              return siteElement;
          }
        }
      }
      return null;
    }

    // applyRules scans through all the rules added via addRule and finds the
    // all rules that are true and pushes the site elements into a list of
    // possible results. Next it tries to find the "highest priority" site
    // elements (e.g. collecting email if not collected, etc). From there
    // we use multi-armed bandit to determine which site element to return
    function apply() {
      const applyingDeferred = deferred();
      const fixedSiteElement = getFixedSiteElement();

      if (fixedSiteElement) {
        applyingDeferred.resolve([fixedSiteElement]);
      } else {
        resolveRules().then(ruleResults => {
          const siteElementsToShow = selectBestElementsForEachGroup(ruleResults);
          applyingDeferred.resolve(siteElementsToShow);
        });
      }

      return applyingDeferred.promise();
    }

    return {
      configuration: () => configuration,
      inspect: () => ({
        allRules: () => rules,
        allElementModels: () => {
          return rules.map((rule) => rule.siteElements).reduce((result, elements) => result.concat(elements), []);
        },
        resolveRules
      }),
      apply
    };
  });
