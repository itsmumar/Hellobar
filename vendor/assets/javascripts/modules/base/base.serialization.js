hellobar.defineModule('base.serialization', [], function () {

  // Replaces all chars used within the serialization schema with a space
  function sanitizeCookieValue(value) {
    return (value + '').replace(/[\^\|\,\;\n\r]/g, ' ');
  }

  // Convert value to a number if it makes sense
  function parseValue(value) {
    if (parseInt(value, 10) == value) {
      value = parseInt(value, 10);
    } else if (parseFloat(value) == value) {
      value = parseFloat(value);
    }
    return value;
  }

  return {
    serialize: function (hash) {
      if (!hash) {
        return '';
      }
      var pairs = [];
      for (var key in hash) {
        var value = hash[key];
        if (typeof(value) != 'function' && typeof(value) != 'object') {
          // Key can not contain ':', but value can
          pairs.push(sanitizeCookieValue(key).replace(/:/g, '-') + ':' + sanitizeCookieValue(value));
        }
      }
      return pairs.join('|');
    },
    deserialize: function (string) {
      if (!string) {
        return {};
      }
      var pairs = string.split('|');
      var results = {};
      for (var i = 0; i < pairs.length; i++) {
        var data = pairs[i].split(':');
        var key = data[0];
        var value = data.slice(1, data.length).join(':');

        results[key] = parseValue(value);
      }
      return results;
    }
  };
});
