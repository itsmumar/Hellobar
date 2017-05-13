import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  init() {
    this.set('selectionInProgress', !this.get('goal'));
  },

  elementTypeIsAlert: Ember.computed.equal('model.type', 'Alert'),
  canUseCallGoal: Ember.computed.not('elementTypeIsAlert'),
  canUseSocialGoal: Ember.computed.not('elementTypeIsAlert'),

  goal: Ember.computed.alias('model.element_subtype'),

  shouldShowEmail: function () {
    return this.get('goal') === 'email' || this.get('selectionInProgress');
  }.property('goal', 'selectionInProgress'),

  shouldShowCall: function () {
    return this.get('canUseCallGoal') && (this.get('goal') === 'call' || this.get('selectionInProgress'));
  }.property('goal', 'selectionInProgress', 'canUseCallGoal'),

  shouldShowSocial: function () {
    return this.get('canUseSocialGoal') && (this.get('goal') === 'social' || this.get('selectionInProgress'));
  }.property('goal', 'selectionInProgress', 'canUseCallGoal'),

  shouldShowTraffic: function () {
    return this.get('goal') === 'traffic' || this.get('selectionInProgress');
  }.property('goal', 'selectionInProgress'),

  shouldShowAnnouncement: function () {
    return this.get('goal') === 'announcement' || this.get('selectionInProgress');
  }.property('goal', 'selectionInProgress'),

  actions: {
    select(goal) {
      if (!this.get('selectionInProgress')) {
        return;
      }
      this.set('goal', goal);
      this.set('selectionInProgress', false);
    },

    initiateSelection() {
      this.set('selectionInProgress', true);
    }

  }

});
