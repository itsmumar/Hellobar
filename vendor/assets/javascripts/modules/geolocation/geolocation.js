hellobar.defineModule('geolocation',
  ['hellobar', 'base.storage', 'base.ajax', 'base.site', 'base.serialization'],
  function (hellobar, storage, ajax, site, serialization) {

    function storageKey() {
      // TODO ideally we should standardize localStorage naming (i.e. HB-something-NNNNN)
      return 'hbglc_' + site.siteId();
    }

    function responseToLocationData(response) {
      var parsedResponse = JSON.parse(response);
      return {
        'gl_cty': parsedResponse.city,
        'gl_ctr': parsedResponse.countryCode,
        'gl_rgn': parsedResponse.region,
        'countryName': parsedResponse.country,
        'regionName': parsedResponse.regionName,
        'cityName': parsedResponse.city
      };
    }

    /**
     * Additional storage class that is capable to store data both in memory and in localStorage.
     * We need memory storage support in order to handle situations when localStorage is disabled
     * (otherwise infinite loop takes place)
     * @constructor
     */
    function GeolocationDataStorage() {
      var _locationData;

      this.setData = function (locationData) {
        _locationData = locationData;

        var expirationDays = 1;
        // TODO adopt: var expirationDays = HB.getVisitorData('dv') === 'mobile' ? 1 : 30;

        // TODO Ideally we should get rid of this kind of custom serialization
        // TODO (however if we do then we need to deal with outdated format saved in storage)
        storage.setValue(storageKey(), serialization.serialize(locationData), expirationDays);
      };

      this.getData = function () {
        if (_locationData) {
          return _locationData;
        }
        return storage.getValue(storageKey());
      };
    }

    var locationDataStorage = new GeolocationDataStorage();

    function syncAsyncGetData(dataKey, onSuccess) {
      function returnValue(locationData) {
        return dataKey ? locationData[dataKey] : locationData;
      }

      var storedLocationData = locationDataStorage.getData();
      var parsedLocationData = typeof storedLocationData === 'string' ? serialization.deserialize(storedLocationData) : storedLocationData;
      if (parsedLocationData) {
        // Return cached geolocation data
        var value = returnValue(parsedLocationData);
        onSuccess && onSuccess(value, true);
        return value;
      } else {
        // No cached data, we're trying to get geolocation data via AJAX call
        ajax.get(configuration.geolocationUrl(), function (response) {
          var locationData = responseToLocationData(response);
          locationDataStorage.setData(locationData);
          onSuccess && onSuccess(returnValue(locationData), false);
        });
        return false;
      }
    }

    var configuration = new hellobar.createModuleConfiguration({
      geolocationUrl: 'string'
    });

    /**
     * @module geolocation {object} Performs geolocation data storing and querying it from the remote server.
     */
    return {
      configuration: function () {
        return configuration;
      },

      /**
       * Gets all geolocation data (or just single specified value).
       * Operation can execute in sync or async way:
       * if we have cached geolocation data, then cached data is returned synchronously from the method
       * (and also passed to onSuccess callback if the callback is specified)
       * otherwise false boolean is returned,
       * then AJAX request to service is done to server and the result is returned asynchronously via onSuccess callback.
       * @param key {string} If specified then only this value will be returned,
       * otherwise all values will be returned as an object.
       * Currently we support keys:
       * countryName, regionName, cityName - new keys
       * gl_cty, gl_ctr, gl_rgn - lagacy keys
       * @param [onSuccess] {function}
       * @returns {string|object|boolean}
       */
      getGeolocationData: function (key, onSuccess) {
        return syncAsyncGetData(key, onSuccess);
      },

      /**
       * Gets region name.
       * The method works in both sync/async ways (see getGeolocationData docs for details).
       * @param [onSuccess] {function}
       * @returns {string|boolean}
       */
      regionName: function (onSuccess) {
        return syncAsyncGetData('regionName', onSuccess);
      },

      /**
       * Gets city name.
       * The method works in both sync/async ways (see getGeolocationData docs for details).
       * @param [onSuccess] {function}
       * @returns {string|boolean}
       */
      cityName: function (onSuccess) {
        return syncAsyncGetData('cityName', onSuccess);
      },

      /**
       * Gets country name.
       * The method works in both sync/async ways (see getGeolocationData docs for details).
       * @param [onSuccess] {function}
       * @returns {string|boolean}
       */
      countryName: function (onSuccess) {
        return syncAsyncGetData('countryName', onSuccess);
      }
    };

  });
