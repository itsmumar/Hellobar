hellobar.defineModule('elements.rules',
  ['base.format', 'base.environment', 'base.timezone', 'base.deferred', 'visitor', 'elements.visibility', 'elements.data'],
  function (format, environment, timezone, deferred, visitor, elementsVisibility, elementsData) {

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


    // applyRules scans through all the rules added via addRule and finds the
    // all rules that are true and pushes the site elements into a list of
    // possible results. Next it tries to find the "highest priority" site
    // elements (e.g. collecting email if not collected, etc). From there
    // we use multi-armed bandit to determine which site element to return
    function applyRules() {
      var i, j, siteElement;
      var visibilityGroups = {};
      var visibilityGroup;
      var visibilityGroupNames = [];
      // First get all the site elements from all the rules that the
      // person matches

      const applyingDeferred = deferred();

      const rulePromises = rules.map((rule) => {
        if (rule.siteElements.length > 0) {
          const ruleResult = ruleTrue(rule);
          return deferred.wrap(ruleResult);
        }
        return deferred.constant(false);
      });
      deferred.all(rulePromises).then((ruleResults) => {
        ruleResults.forEach((result, ruleIndex) => {
          if (result) {
            rules[ruleIndex].siteElements.forEach((siteElement) => {
              visibilityGroup = siteElement.type;
              // For showing multiple elements at the same time a modal and a takeover are the same thing
              if (siteElement.type === 'Modal' || siteElement.type === 'Takeover')
                visibilityGroup = 'Modal/Takeover';
              if (!visibilityGroups[visibilityGroup]) {
                visibilityGroups[visibilityGroup] = [];
                visibilityGroupNames.push(visibilityGroup);
              }
              visibilityGroups[visibilityGroup].push(siteElement);
            });
          }
        });
        // Now we have all elements that can be shown based on the rules
        // broken up into visibility groups
        // The next step is to pick one per visibility group
        var siteElementResults = [];
        // We need to specify the order that elements appear in. Whichever is first
        // in the array is on top
        var visibilityOrder = ['Modal/Takeover', 'Alert', 'Slider', 'Bar'];
        for (i = 0; i < visibilityOrder.length; i++) {
          var visibleElements = visibilityGroups[visibilityOrder[i]];
          if (visibleElements) {
            siteElement = getBestElement(visibleElements);
            if (siteElement && elementsVisibility.shouldShowElement(siteElement)) {
              siteElementResults.push(siteElement);
            }
          }
        }
        applyingDeferred.resolve(siteElementResults);
      });
      return applyingDeferred.promise();
    }


    // Returns the best element to show from a group of elements
    function getBestElement(elements) {
      elements = filterMostRelevantElements(elements);

      var i, siteElement;
      var possibleSiteElements = {};
      for (i = 0; i < elements.length; i++) {
        siteElement = elements[i];
        if (!possibleSiteElements[siteElement.subtype]) {
          possibleSiteElements[siteElement.subtype] = [];
        }
        possibleSiteElements[siteElement.subtype].push(siteElement);
      }

      // Now we narrow down based on the "value" of the site elements
      // (collecting emails is considered more valuable than clicking links
      // for example)
      possibleSiteElements =
        possibleSiteElements.email ||
        environment.isMobileDevice() && possibleSiteElements.call || // consider 'call' elements only on mobile devices
        possibleSiteElements.social ||
        possibleSiteElements.traffic ||
        possibleSiteElements.announcement;

      // If we have no elements then stop
      if (!possibleSiteElements || possibleSiteElements.length === 0) {
        return;
      }

      // If we only have one element just show it
      if (possibleSiteElements.length === 1) {
        return possibleSiteElements[0];
      }

      // First we should see if the visitor has seen any of these site elements
      // If so we should show them the same element again for a consistent
      // user experience.
      for (i = 0; i < possibleSiteElements.length; i++) {
        if (elementsData.getData(possibleSiteElements[i].id, 'nv')) {
          return possibleSiteElements[i];
        }
      }
      // We have more than one possibility so first we check for site elements
      // with less than 1000 views
      var siteElementsWithoutEnoughViews = [];
      for (i = 0; i < possibleSiteElements.length; i++) {
        if (possibleSiteElements[i].views < 1000) {
          siteElementsWithoutEnoughViews.push(possibleSiteElements[i]);
        }
      }
      // If we have at least one element without enough views pick
      // randomly from them
      if (siteElementsWithoutEnoughViews.length >= 1) {
        return siteElementsWithoutEnoughViews[Math.floor((Math.random() * siteElementsWithoutEnoughViews.length))]
      }
      // So now we have more than one site element all with enough views
      // We need to determine if we are going to explore or exploit
      if (Math.random() >= 0.9) {
        // Explore mode
        // Just return a random site element
        return possibleSiteElements[Math.floor((Math.random() * possibleSiteElements.length))]
      }
      else {
        // Exploit mode
        // Return the site element with the highest conversion rate
        possibleSiteElements.sort(function (a, b) {
          if (a.conversion_rate < b.conversion_rate)
            return 1;
          else if (a.conversion_rate > b.conversion_rate)
            return -1;
          return 0;
        });
        // Return the top value
        return possibleSiteElements[0];
      }
    }


    // Get elements that are most relevant, namely they meet the most narrow set of rules.
    // For example, having 2 similar modals: one set to be shown to everybody (0 conditions),
    // and another - to mobile visitors only (1 condition), we should always show the latter on mobile devices.
    function filterMostRelevantElements(elements) {
      if (elements.length <= 1) {
        return elements; //no need to filter
      }

      var rules = elements.map(function (element) {
        return element.rule;
      });

      rules = filterMostRelevantRules(rules);

      // filter elements that correspond to the most relevant set of rules
      return elements.filter(function (element) {
        return rules.indexOf(element.rule) >= 0;
      });
    }


    // Find the most relevant (narrow) set of rules.
    // For "all" rules the most narrow set is one with the maximum number of conditions (X and Y and Z < X and Y)
    // For "any" rules the most narrow set is one with the minimum number of conditions (X or Y < X or Y or Z), except for 0
    // When the 2 kinds of rules intersect, "and" has always higher priority (X and Y < X or Y).
    function filterMostRelevantRules(rules) {
      if (rules.length <= 1) {
        return rules;
      }

      var basis = 10; //basic multiplier for weight calculation
      var groups = {}; //hash of weight:rules pairs

      //Step 1: Go through the array, calculate each rule's weight and put it into the appropriate group
      rules.forEach(function (rule) {
        var weight;
        if (rule.conditions.length === 0) {
          //the least relevant rule - it matches everything
          weight = 0;
        } else {
          //for "all" rule - the more conditions it has, the more relevant it is, the higher weight it should have (multiplication)
          //for "any" rule - the more conditions it has, the less relevant it is, the lower weight it should have (division)
          weight = rule.matchType === 'all' ? basis * rule.conditions.length : basis / rule.conditions.length;
        }

        if (!groups[weight])
          groups[weight] = [];

        groups[weight].push(rule);
      });

      //Step 2: Find the maximum weight and return the corresponding group of rules
      var maxWeight = Math.max.apply(null, Object.keys(groups));
      return groups[maxWeight];
    }


    // Checks if the rule is true by checking each of the conditions and
    // the matching logic of the rule (any vs all).
    function ruleTrue(rule) {
      const results = rule.conditions.map((condition) => conditionTrue(condition));
      const checkResult = (results) => {
        if (rule.matchType === 'any' && results.filter((result) => result === true).length > 0) {
          return true;
        }
        if (rule.matchType !== 'any' && results.filter((result) => result === false).length > 0) {
          return false;
        }
        return undefined;
      };
      const checkedResult = checkResult(results);
      if (checkedResult !== undefined) {
        return checkedResult;
      }

      return deferred.all(results.map((result) => result instanceof deferred.Promise ? result : deferred.constant(result))).then((finalResults) => {
        const checkedResult = checkResult(finalResults);
        if (checkedResult !== undefined) {
          return checkedResult;
        }
        // If we needed to match any condition (and we had at least one)
        // and didn't yet return false
        if (rule.matchType === 'any' && rule.conditions.length > 0) {
          return false;
        }
        return true;
      });
    }

    function timeConditionTrue(condition) {
      var conditionHour = parseInt(condition.value[0]),
        conditionMinute = parseInt(condition.value[1]),
        conditionZoneOffset = condition.timezone_offset,
        currentConditionTime = timezone.nowInTimezone(conditionZoneOffset);

      if (applyOperand(currentConditionTime.getHours(), condition.operand, conditionHour, condition.segment)) {
        return true;
      } else if (currentConditionTime.getHours() === conditionHour) {
        return applyOperand(currentConditionTime.getMinutes(), condition.operand, conditionMinute, condition.segment)
      } else {
        return false;
      }
    }

    function geoLocationConditionTrue(condition) {
      const currentValue = getSegmentValue(condition.segment);

      return deferred
        .wrap(currentValue)
        .then(value => applyCondition(value, condition));
    }

    function applyCondition(value, condition) {
      return applyOperands(value, condition.operand, condition.value, condition.segment);
    }

    function regionConditionTrue(condition) {
      const region = getSegmentValue('region');
      const regionName = getSegmentValue('regionName');

      return deferred.all([region, regionName]).then(results => {
        return results
          .map(value => applyCondition(value, condition))
          .find(ok => ok)
      })
    }

    function handleGeoLocationCondition(condition) {
      if (condition.segment === 'gl_rgn') {
        return regionConditionTrue(condition);
      }
      return geoLocationConditionTrue(condition);
    }

    // Determines if the condition (a rule is made of one or more conditions)
    // is true. It gets the current value and applies the operand
    function conditionTrue(condition) {
      // Handle for URL Query
      if (condition.segment === 'pq') {
        var conditionKey = condition.value.split('=')[0];
        var currentValue = getSegmentValue(condition.segment)[conditionKey];
        var values = condition.value.split('=')[1] || '';
      }
      else if (condition.segment === 'tc')
        return timeConditionTrue(condition);
      else if (condition.segment.indexOf('gl_') !== -1) {
        return handleGeoLocationCondition(condition);
      } else {
        currentValue = getSegmentValue(condition.segment);
        values = condition.value;
      }

      // Now we need to apply the operands
      // If it's an array of values this is true if the operand is true for any of the values

      // We don't want to mess with the array for the between operand
      if (condition.operand === 'between')
        return applyOperand(currentValue, condition.operand, values, condition.segment);

      return applyOperands(currentValue, condition.operand, values, condition.segment);
    }

    // Sanitizes the value parameter based on the segment and input
    // Value is the value to sanitize
    // Input is the users value condition
    function sanitizeConditionValue(segment, value, input) {
      if (segment === 'pu' || segment === 'pp' || segment === 'pup') {
        var relative = /^\//.test(input);
        value = format.normalizeUrl(value, relative);
      }

      return value;
    }


    // Applies the operand specified to the array of possible values
    function applyOperands(currentValue, operand, values, segment) {
      // Put the value in an array if it is not an array
      if (typeof(values) != 'object' || typeof(values.length) != 'number')
        values = [values];

      // For negative/excluding operands we use "and" logic:
      if (operand.match(/not/)) {
        // Must be true for all so a single false means it is false for whole condition
        for (var i = 0; i < values.length; i++) {
          if (!applyOperand(currentValue, operand, values[i], segment))
            return false;
        }
        return true;
      }
      else {
        // For including/positive operands we use "or" logic
        // Must be true for just one, so a single true is true for condition
        for (i = 0; i < values.length; i++) {
          if (applyOperand(currentValue, operand, values[i], segment))
            return true;
        }
        return false;
      }
    }

    // Applies the operand specified to the arguments passed in
    function applyOperand(currentValue, operand, input, segment) {
      var a = sanitizeConditionValue(segment, currentValue, input);
      var b = sanitizeConditionValue(segment, input, input);

      switch (operand) {
        case 'is':
        case 'equals':
          if (typeof a === 'string' && typeof b === 'string') {
            var regex = new RegExp('^' + sanitizeRegexString(b).replace('*', '.*') + '$');
            return !!a.match(regex);
          }
          return a == b;
        case 'every':
          return a % b == 0;
        case 'is_not':
        case 'does_not_equal':
          return a != b;
        case 'includes':
          if (typeof a === 'undefined' && b === '')
            return false;
          if (typeof a === 'string' && typeof b === 'string') {
            var regex = new RegExp(sanitizeRegexString(b).replace('*', '.*'));
            return !!a.match(regex);
          }

          return stringify(a).indexOf(stringify(b)) != -1;
        case 'does_not_include':
          if (typeof a === 'undefined' && b === '')
            return true;
          return stringify(a).indexOf(stringify(b)) == -1;
        case 'before':
        case 'less_than':
          return a < b;
        case 'less_than_or_equal':
          return a <= b;
        case 'after':
        case 'greater_than':
          return a > b;
        case 'greater_than_or_equal':
          return a >= b;
        case 'between':
        case 'is_between':
          return a >= b[0] && a <= b[1];
      }
    }

    // Returns a normalized string value
    // Used for applying operands
    function stringify(o) {
      return (o + '').toLowerCase();
    }

    // Escapes all regex characters EXCEPT for the asterisk
    function sanitizeRegexString(str) {
      return str.replace(/[-[\]{}()+?.,\\^$|#\s]/g, '\\$&');
    }

    // Gets the current segment value that will be compared to the conditions
    // value
    function getSegmentValue(segmentName) {
      // Convert long names to short names
      if (segmentName === 'url')
        segmentName = 'pu';
      else if (segmentName === 'device')
        segmentName = 'dv';
      else if (segmentName === 'country')
        segmentName = 'co';
      else if (segmentName === 'referrer' || segmentName === 'referer')
        segmentName = 'rf';
      else if (segmentName === 'date')
        segmentName = 'dt';

      // All other segment names
      return visitor.getData(segmentName);
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


    return {
      configuration: () => configuration,
      inspect: () => ({
        allRules: () => rules,
        allElementModels: () => {
          return rules.map((rule) => rule.siteElements).reduce((result, elements) => result.concat(elements), []);
        }
      }),
      applyRules,
      getFixedSiteElement
    };

  });
