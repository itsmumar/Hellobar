hellobar.defineModule('elements.relevance',
  ['base.environment', 'elements.data'],
  function (environment, elementsData) {
    const randomItem = (items) => {
      const index = Math.floor((Math.random() * items.length))
      return items[index]
    }

    class MostRelevantElement {
      constructor(possibleSiteElements) {
        this.possibleSiteElements = possibleSiteElements || [];

        // We have more than one possibility so first we check for site elements
        // with less than 1000 views
        this.siteElementsWithoutEnoughViews = this.possibleSiteElements.filter(element => element.views < 1000);

        // We need to determine if we are going to explore or exploit
        // in case we couldn't find better element
        //  `Explore` means returning random element
        //  `Exploit` means returning most converting element (highest conversion_rate)
        this.mode = Math.random() >= 0.9 ? 'Explore' : 'Exploit'
      }

      randomElementWithoutEnoughViews() {
        // If we have at least one element without enough views pick
        // randomly from them
        if (this.siteElementsWithoutEnoughViews.length >= 1) {
          return randomItem(this.siteElementsWithoutEnoughViews)
        }
      }

      elementThatUserSeen() {
        for (let i = 0; i < this.possibleSiteElements.length; i++) {
          const element = this.possibleSiteElements[i];

          if (elementsData.getData(element.id, 'nv')) {
            return element
          }
        }
      }

      randomElement() {
        if (this.mode === 'Explore') {
          return randomItem(this.possibleSiteElements)
        }
      }

      highestConversionRateElement() {
        if (this.mode === 'Exploit') {
          this.possibleSiteElements.sort((a, b) => {
            if (a.conversion_rate < b.conversion_rate)
              return 1;
            else if (a.conversion_rate > b.conversion_rate)
              return -1;
            return 0;
          });

          // Return the site element with the highest conversion rate
          return this.possibleSiteElements[0];
        }
      }

      theOnlyElement() {
        // If we only have one element just show it
        if (this.possibleSiteElements.length === 1) {
          return this.possibleSiteElements[0];
        }
      }
    }

    function findPossibleSiteElements(elements) {
      let relevantElements = filterMostRelevantElements(elements);

      const groupBySubtype = (possibleSiteElements, element) => {
        if (!possibleSiteElements[element.subtype]) {
          possibleSiteElements[element.subtype] = [];
        }
        possibleSiteElements[element.subtype].push(element);

        return possibleSiteElements;
      };

      const possibleSiteElements = relevantElements.reduce(groupBySubtype, {});

      // Now we narrow down based on the "value" of the site elements
      // (collecting emails is considered more valuable than clicking links
      // for example)
      return possibleSiteElements.email ||
        environment.isMobileDevice() && possibleSiteElements.call || // consider 'call' elements only on mobile devices
        possibleSiteElements.social ||
        possibleSiteElements.traffic ||
        possibleSiteElements.announcement;
    }

    // Get elements that are most relevant, namely they meet the most narrow set of rules.
    // For example, having 2 similar modals: one set to be shown to everybody (0 conditions),
    // and another - to mobile visitors only (1 condition), we should always show the latter on mobile devices.
    function filterMostRelevantElements(elements) {
      if (elements.length <= 1) {
        return elements; //no need to filter
      }

      let rules = findMostRelevantRules(elements.map(element => element.rule));

      // filter elements that correspond to the most relevant set of rules
      return elements.filter(element => rules.indexOf(element.rule) >= 0);
    }

    function calculateRuleWeight(rule) {
      const basis = 10; //basic multiplier for weight calculation
      const conditionsCount = rule.conditions.length;

      //the least relevant rule - it matches everything
      if (conditionsCount === 0) {
        return 0;
      }

      //for "all" rule - the more conditions it has, the more relevant it is, the higher weight it should have (multiplication)
      //for "any" rule - the more conditions it has, the less relevant it is, the lower weight it should have (division)
      return rule.matchType === 'all' ? basis * conditionsCount : basis / conditionsCount;
    }

    // Find the most relevant (narrow) set of rules.
    // For "all" rules the most narrow set is one with the maximum number of conditions (X and Y and Z < X and Y)
    // For "any" rules the most narrow set is one with the minimum number of conditions (X or Y < X or Y or Z), except for 0
    // When the 2 kinds of rules intersect, "and" has always higher priority (X and Y < X or Y).
    function findMostRelevantRules(rules) {
      if (rules.length <= 1) {
        return rules;
      }

      //Step 1: Go through the array, calculate each rule's weight and put it into the appropriate group
      const groups = rules.reduce((weights, rule) => {
        const ruleWeight = calculateRuleWeight(rule);

        if (!weights[ruleWeight])
          weights[ruleWeight] = [];

        weights[ruleWeight].push(rule);

        return weights;
      }, {});

      //Step 2: Find the maximum weight and return the corresponding group of rules
      var maxWeight = Math.max.apply(null, Object.keys(groups));

      return groups[maxWeight];
    }

    // Returns the best element to show from a group of elements
    function getBestElement(elements) {
      const possibleSiteElements = findPossibleSiteElements(elements);

      // If we have no elements then stop
      if (!possibleSiteElements || possibleSiteElements.length === 0) {
        return;
      }

      const service = new MostRelevantElement(possibleSiteElements);

      return service.theOnlyElement() ||
        service.elementThatUserSeen() ||
        service.randomElementWithoutEnoughViews() ||
        service.highestConversionRateElement() ||
        service.randomElement();
    }

    return {
      getBestElement
    };

  });
