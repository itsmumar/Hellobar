import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  // TODO get rid of this global usage
  countries: HBEditor.countryCodes,

  applicationController: Ember.inject.controller('application'),

  validation: Ember.inject.service('validation'),
  bus: Ember.inject.service('bus'),

  selectedCountry: (function() {
    const countryCode = this.get('model.phone_country_code');
    return _.find(this.countries, (country) => country.code === countryCode);
  }).property('model.phone_country_code'),


  actions: {
    selectCallCountryCall(country) {
      this.set('model.phone_country_code', country.code);
    },

    onPhoneNumberBlur() {
      this.get('validation').validate('phone_number', this.get('model')).then(() => {
        this.get('bus').trigger('hellobar.core.validation.succeeded');
      }, (failures) => {
        // Validation failed
        this.get('bus').trigger('hellobar.core.validation.failed', failures);
      });
    }
  }

});
