import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  applicationController: Ember.inject.controller('application'),

  setDefaults() {
    if (!this.get('model')) {
      return false;
    }

    this.set('model.headline', 'Talk to us to find out more');
    this.set('model.link_text', 'Call Now');
    return this.set('model.element_subtype', 'call');
  },

  inputIsInvalid: function () {
    return !!(
      Ember.isEmpty(this.get('model.headline')) ||
      Ember.isEmpty(this.get('model.link_text')) || !isValidNumber(this.get('model.phone_number'), this.get('model.phone_country_code'))
    );
  }.property(
    'model.link_text',
    'model.headline',
    'model.phone_number',
    'model.phone_country_code'
  ),

  // TODO get red of this global usage
  countries: HBEditor.countryCodes,

  selectedCountry: function() {
    return _.find(this.get('countries'), (country) => country.code === this.get('model.phone_country_code'))
  }.property('countries', 'model.phone_country_code'),

  actions: {
    closeInterstitial() {
      return this.transitionToRoute('style');
    },
    selectCountry(country) {
      this.set('model.phone_country_code', country.code);
    }
  }
});
