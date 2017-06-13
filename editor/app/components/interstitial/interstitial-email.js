import Ember from 'ember';

export default Ember.Component.extend({
  inputIsInvalid: function () {
    return !!(
      Ember.isEmpty(this.get('model.headline')) ||
      Ember.isEmpty(this.get('model.link_text'))
    );
  }.property(
    'model.link_text',
    'model.headline'
  ),

  actions: {
    closeInterstitial() {
      this.get('router').transitionTo('styles');
    }
  }
});
