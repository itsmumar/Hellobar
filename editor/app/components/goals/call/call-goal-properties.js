import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extends({

  /**
   * @property {object} Application model
   */
  model: null,

  countries: Ember.inject.service(),
  validation: Ember.inject.service(),
  bus: Ember.inject.service(),

  selectedCountry: function () {
    const countryCode = this.get('model.phone_country_code');
    return _.find(this.get('countries.all'), (country) => country.code === countryCode);
  }.property('model.phone_country_code'),


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
