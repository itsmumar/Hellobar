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

  isCall: Ember.computed.equal('model.element_subtype', 'call'),

  actions: {
    selectGoalAndType (goal, type) {
      const routeName = 'interstitial.' + goal + '.' + type;
      this.get('router').transitionTo(routeName);
    }
  }
});
