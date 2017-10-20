import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  theming: Ember.inject.service(),

  init() {
    this._super();
    this.set('selectionInProgress', !this.get('goal'));
  },

  goal: Ember.computed.alias('model.element_subtype'),

  shouldShowEmail: function () {
    return this.get('goal') === 'email' || this.get('selectionInProgress');
  }.property('goal', 'selectionInProgress'),

  shouldShowCall: function () {
    return (this.get('goal') === 'call' || this.get('selectionInProgress'));
  }.property('goal', 'selectionInProgress', 'canUseCallGoal'),

  shouldShowSocial: function () {
    return (_.startsWith(this.get('goal'), 'social') || this.get('selectionInProgress'));
  }.property('goal', 'selectionInProgress', 'canUseCallGoal'),

  shouldShowTraffic: function () {
    return this.get('goal') === 'traffic' || this.get('selectionInProgress');
  }.property('goal', 'selectionInProgress'),

  shouldShowAnnouncement: function () {
    return this.get('goal') === 'announcement' || this.get('selectionInProgress');
  }.property('goal', 'selectionInProgress'),

  shouldShowInitiateSelection: function () {
    return !this.get('selectionInProgress') && this.get('theming.currentThemeIsGeneric');
  }.property('selectionInProgress', 'theming.currentThemeIsGeneric'),

  actions: {
    select(goal) {
      if (!this.get('selectionInProgress')) {
        return;
      }
      this.set('goal', goal === 'social' ? 'social/like_on_facebook' : goal);
      this.get('theming').resetThemeIfNeeded();
      this.set('selectionInProgress', false);
    },

    initiateSelection() {
      this.set('selectionInProgress', true);
    }

  }

});
