hellobar.defineModule('geolocation',
  ['base.storage', 'base.ajax', 'base.site', 'base.serialization'],
  function (storage, ajax, site, serialization) {

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

    function ModuleConfiguration() {
      var _geolocationUrl;
      this.geolocationUrl = function (geolocationUrl) {
        return geolocationUrl ? (_geolocationUrl = geolocationUrl) : _geolocationUrl;
      };
    }

    var configuration = new ModuleConfiguration();

    return {
      configuration: function () {
        return configuration;
      },

      getGeolocationData: function (key, onSuccess) {
        return syncAsyncGetData(key, onSuccess);
      },

      regionName: function (onSuccess) {
        return syncAsyncGetData('regionName', onSuccess);
      },

      cityName: function (onSuccess) {
        return syncAsyncGetData('cityName', onSuccess);
      },

      countryName: function (onSuccess) {
        return syncAsyncGetData('countryName', onSuccess);
      }
    };

  });
