import Ember from 'ember';

// GLOBALS: isValidNumber function
const isValidNumber = window.isValidNumber;
const URL_REGEXP = /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?/gi;

/**
 * @class ModelValidation
 * Provides logic to initialize model validation rules
 */
export default Ember.Service.extend({
  validation: Ember.inject.service(),
  bus: Ember.inject.service(),

  initializeValidation() {
    this.get('validation').add('phone_number', [{
      fieldName: 'phone_number',
      validator: (model) => {
        if (Ember.get(model, 'element_subtype') === 'call') {
          const phoneNumber = Ember.get(model, 'phone_number');
          if (!phoneNumber) {
            return 'Phone number is required';
          }
          const countryCode = Ember.get(model, 'phone_country_code');
          if (!isValidNumber(phoneNumber, countryCode)) {
            return 'Wrong phone number for specified country';
          }
        }
        return null;
      }
    }]);

    this.get('validation').add('url', [{
      fieldName: 'url',
      validator: (model) => {
        if (Ember.get(model, 'element_subtype') === 'traffic') {
          const url = Ember.get(model, 'settings.url');

          if (!url || !url.match(URL_REGEXP)) {
            return 'link URL is required';
          }
        }
        return null;
      }
    }]);

    this.get('validation').add('url_to_like', [{
      fieldName: 'url',
      validator: (model) => {
        if (Ember.get(model, 'element_subtype').match(/social/)) {
          const url = Ember.get(model, 'settings.url_to_like');

          if (!url || !url.match(URL_REGEXP)) {
            return 'URL to like is required';
          }
        }
        return null;
      }
    }]);

  }
});
