import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  showFacebookUrl: false,

  facebookLikeOptions: [
    {value: 'homepage', label: 'Home Page'},
    {value: 'use_location_for_url', label: 'Current Page Visitor is Viewing'},
    {value: 'other', label: 'Other'}
  ],

  selectedFacebookLikeValue: 'homepage',

  selectedFacebookLikeOption: ( function() {
    const value = this.get('selectedFacebookLikeValue');
    const options = this.get('facebookLikeOptions');
    return _.find(options, (option) => option.value === value);
  }).property('selectedFacebookLikeValue'),



  inputIsInvalid: ( function () {
    return !!(
      Ember.isEmpty(this.get('model.headline')) ||
      (!this.get('model.settings.use_location_for_url') &&
      Ember.isEmpty(this.get('model.settings.url_to_like')))
    );
  }).property(
    'model.settings.use_location_for_url',
    'model.settings.url_to_like',
    'model.headline'
  ),

  actions: {

    closeInterstitial() {
      this.get('router').transitionTo('styles');
    },

    selectFacebookLikeOption(option) {
      const value = option.value;
      this.set('selectedFacebookLikeValue', option.value);

      this.set('showFacebookUrl', false);
      this.set('model.settings.use_location_for_url', false);

      if (value === 'homepage') {
        this.set('model.settings.url_to_like', this.get('model.site.url'));
      } else if (value === 'use_location_for_url') {
        this.set('model.settings.use_location_for_url', true);
      } else {
        this.set('showFacebookUrl', true);
      }
    }

  }

});
