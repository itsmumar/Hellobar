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
          this.removeValue(key);
        }
      }
      return undefined;
    };

    this.removeValue = function (key) {
      return localStorage.removeItem(key);
    };
  }

  var valueStorage = new ValueStorage();

  /**
   * @module base.storage {object} Module that supports client-side data storing.
   */
  return {
    /**
     * Stores data in the client-side storage
     * @param key {string} Unique key
     * @param value {object|string|number|boolean} Value to store
     * @param expiration {number|Date} Expiration period, can be specified with explicit time moment (Date instance)
     * or by specifying number of days until data is considered to be expired.
     */
    setValue: function (key, value, expiration) {
      valueStorage.setValue(key, value, expiration);
    },

    /**
     * Gets data from the client-side storage
     * @param key {string} Unique key to get value by
     * @returns {object|string|number|boolean}
     */
    getValue: function (key) {
      return valueStorage.getValue(key);
    },

    /**
     * Removes data from the client-side storage
     * @param key {string} Unique key to remove
     * @returns {undefined}
     */
    removeValue: function (key) {
      return valueStorage.removeValue(key);
    }
  };

});
