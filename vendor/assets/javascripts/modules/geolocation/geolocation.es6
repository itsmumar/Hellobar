hellobar.defineModule('geolocation',
  ['hellobar', 'base.storage', 'base.ajax', 'base.site', 'base.serialization', 'base.deferred'],
  function (hellobar, storage, ajax, site, serialization, deferred) {

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
        'region': parsedResponse.region,
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

    function syncAsyncGetData(dataKey) {
      function returnValue(locationData) {
        return dataKey ? locationData[dataKey] : locationData;
      }

      const deferredValue = deferred();
      const storedLocationData = locationDataStorage.getData();
      const parsedLocationData = typeof storedLocationData === 'string' ? serialization.deserialize(storedLocationData) : storedLocationData;

      if (parsedLocationData) {
        // Return cached geolocation data
        const value = returnValue(parsedLocationData);
        deferredValue.resolve(value);
      } else {
        // No cached data, we're trying to get geolocation data via AJAX call
        ajax.get(configuration.geolocationUrl(), function (response) {
          var locationData = responseToLocationData(response);
          locationDataStorage.setData(locationData);
          deferredValue.resolve(returnValue(locationData));
        });
      }
      return deferredValue.promise();
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
       * @param key {string} If specified then only this value will be returned,
       * otherwise all values will be returned as an object.
       * Currently we support keys:
       * countryName, regionName, cityName - new keys
       * gl_cty, gl_ctr, gl_rgn - lagacy keys
       * @returns {deferred.Promise}
       */
      getGeolocationData: function (key) {
        return syncAsyncGetData(key);
      },

      /**
       * Gets region name.
       * @returns {deferred.Promise}
       */
      regionName: function () {
        return syncAsyncGetData('regionName');
      },

      /**
       * Gets city name.
       * @returns {deferred.Promise}
       */
      cityName: function () {
        return syncAsyncGetData('cityName');
      },

      /**
       * Gets country name.
       * @returns {deferred.Promise}
       */
      countryName: function () {
        return syncAsyncGetData('countryName');
      }
    };

  });
