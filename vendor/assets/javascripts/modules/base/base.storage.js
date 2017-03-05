hellobar.defineModule('base.storage', [], function () {

  /**
   * @class ValueStorage
   * Abstracts out the way of values on client side (currently localStorage is used).
   */
  function ValueStorage() {

    function dateToTimestamp(date) {
      return date.toISOString();
    }

    function currentTimestamp() {
      return dateToTimestamp(new Date());
    }

    function expirationTimestamp(expirationParameter) {
      var date;
      if (expirationParameter instanceof Date) {
        // expiration time specified explicitly with Date object
        date = expirationParameter;
      } else if (typeof expirationParameter === 'number') {
        // expirationParameter is expiration day count
        date = new Date();
        date.setDate(date.getDate() + expirationParameter);
      } else {
        // by default expiration period is one year
        date = new Date();
        date.setDate(date.getDate() + 365);
      }
      return dateToTimestamp(date);
    }

    this.setValue = function (key, value, expiration) {
      localStorage.setItem(key, JSON.stringify({
        value: value,
        expiration: expirationTimestamp(expiration)
      }));
    };

    this.getValue = function (key) {
      var storedObjectAsString = localStorage.getItem(key);
      if (storedObjectAsString) {
        var storedObject = JSON.parse(storedObjectAsString);
        if (storedObject.expiration > currentTimestamp()) {
          return storedObject.value;
        } else {
          localStorage.removeItem(key);
        }
      }
      return undefined;
    };

  }

  var valueStorage = new ValueStorage();


  return {
    setValue: function (key, value, expiration) {
      valueStorage.setValue(key, value, expiration);
    },
    getValue: function (key) {
      return valueStorage.getValue(key);
    }
  };

});
