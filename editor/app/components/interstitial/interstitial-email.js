import Ember from 'ember';

export default Ember.Component.extend({
  showEmailVolume: false,

  monthlyPageviews: function () {
    return this.get('model.site.monthly_pageviews') || 0;
  }.property(),

  formattedMonthlyPageviews: function () {
    return this.get('monthlyPageviews').toLocaleString();
  }.property(),

  hasEnoughSubscribers: function () {
    return this.get('monthlyPageviews') > 1000;
  }.property(),

  calculatedSubscribers: function () {
    return Math.round(this.get('monthlyPageviews') * 0.005);
  }.property(),

  formattedCalculatedSubscribers: function () {
    return this.get('calculatedSubscribers').toLocaleString();
  }.property(),

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
      this.get('router').transitionTo('goals');
    }
  }
});
