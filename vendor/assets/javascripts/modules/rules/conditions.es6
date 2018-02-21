hellobar.defineModule('rules.conditions',
  ['base.format', 'base.timezone', 'base.deferred', 'visitor', 'geolocation'],
  function (format, timezone, deferred, visitor, geolocation) {

    function applyCondition(value, condition) {
      return applyOperands(value, condition.operand, condition.value, condition.segment);
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

    function regionConditionTrue(condition) {
      return geolocation.getGeolocationData().then(geolocationData => {
        const region = geolocationData.region;
        const regionName = geolocationData.regionName;

        return applyCondition(region, condition) ||
          applyCondition(regionName, condition);
      })
    }

    function handleGeoLocationCondition(condition) {
      if (condition.segment === 'gl_rgn') {
        return regionConditionTrue(condition);
      }
      return geoLocationConditionTrue(condition);
    }

    // Sanitizes the value parameter based on the segment and input
    // Value is the value to sanitize
    // Input is the users value condition
    function sanitizeConditionValue(segment, value, input) {
      if (segment === 'pp' || segment === 'pup') {
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
      if (segmentName === 'device')
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

    // Determines if the condition (a rule is made of one or more conditions)
    // is true. It gets the current value and applies the operand
    function resolve(condition) {
      let currentValue;
      let values;

      // Handle for URL Query
      if (condition.segment === 'pq') {
        const conditionKey = condition.value.split('=')[0];
        currentValue = getSegmentValue(condition.segment)[conditionKey];
        values = condition.value.split('=')[1] || '';
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

    return {
      resolve
    };
  });
