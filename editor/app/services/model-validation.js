import Ember from 'ember';

// GLOBALS: isValidNumber function
const isValidNumber = window.isValidNumber;
const maxCookieDuration = 10000;

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

          if (!url) {
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

          if (!url) {
            return 'URL to like is required';
          }
        }
        return null;
      }
    }]);

    this.get('validation').add('cookie_settings.duration', [{
      fieldName: 'url',
      validator: (model) => {
        const cookieDuration = Number(Ember.get(model, 'settings.cookie_settings.duration'));

        if (cookieDuration > maxCookieDuration) {
          return 'Cookie Duration should not exceed 10000';
        }

        return null;
      }
    }]);

    this.get('validation').add('cookie_settings.success_duration', [{
      fieldName: 'url',
      validator: (model) => {
        const cookieDuration = Number(Ember.get(model, 'settings.cookie_settings.success_duration'));

        if (cookieDuration > maxCookieDuration) {
          return 'Success Cookie Duration should not exceed 10000';
        }

        return null;
      }
    }]);

  }
});
