import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

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

  countries: Ember.inject.service(),

  selectedCountry: function() {
    return _.find(this.get('countries.all'), (country) => country.code === this.get('model.phone_country_code'))
  }.property('countries.all', 'model.phone_country_code'),

  actions: {
    closeInterstitial() {
      this.get('router').transitionTo('styles');
    },
    selectCountry(country) {
      this.set('model.phone_country_code', country.code);
    }
  }
});
