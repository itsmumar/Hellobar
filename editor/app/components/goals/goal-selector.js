import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  goalSelectionInProgress: false,

  elementTypeIsAlert: Ember.computed.equal('model.type', 'Alert'),
  canUseCallGoal: Ember.computed.not('elementTypeIsAlert'),
  canUseSocialGoal: Ember.computed.not('elementTypeIsAlert'),

  goalListCssClasses: (function () {
    let classes = ['step-link-wrapper'];
    !this.get('goalSelectionInProgress') && (classes.push('is-selected'));
    return classes.join(' ');
  }).property('goalSelectionInProgress'),

  actions: {
    closeDropdown() {
      this.set('goalSelectionInProgress', false);
    },

    changeSettings() {
      this.set('goalSelectionInProgress', true);
      return false;
    }
  }

});
