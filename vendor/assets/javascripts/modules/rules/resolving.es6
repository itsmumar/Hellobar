hellobar.defineModule('rules.resolving',
  ['base.format', 'base.timezone', 'base.deferred', 'visitor', 'geolocation', 'rules.conditions'],
  function (format, timezone, deferred, visitor, geolocation, conditions) {

    // Checks if the rule is true by checking each of the conditions and
    // the matching logic of the rule (any vs all).
    function resolve(rule) {
      const results = rule.conditions.map((condition) => conditions.resolve(condition));
      const checkResult = (results) => {
        if (rule.matchType === 'any' && results.filter((result) => result === true).length > 0) {
          return { rule, ruleActive: true };
        }
        if (rule.matchType !== 'any' && results.filter((result) => result === false).length > 0) {
          return { rule, ruleActive: false };
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
          return { rule, ruleActive: false };
        }
        return { rule, ruleActive: true };
      });
    }

    return {
      resolve
    };
  });
