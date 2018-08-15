import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  theming: Ember.inject.service(),

  goal: Ember.computed.alias('model.element_subtype'),
  isEmail: Ember.computed.equal('goal', 'email'),
  isCall: Ember.computed.equal('goal', 'call'),
  isTraffic: Ember.computed.equal('goal', 'traffic'),
  isAnnouncement: Ember.computed.equal('goal', 'announcement'),
  isSocial: function () {
    return _.startsWith(this.get('goal'), 'social');
  }.property('goal'),

  actions: {
    select(goal) {
      this.set('goal', goal === 'social' ? 'social/like_on_facebook' : goal);
      this.get('theming').resetThemeIfNeeded();
      this.set('model.wiggle_button', false); // turn wiggling off
    }
  }
});
