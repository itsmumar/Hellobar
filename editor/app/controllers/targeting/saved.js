import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  targetingController: Ember.inject.controller('targeting'),

  ruleOptions: Ember.computed('targetingController.ruleOptions'),

  selectedRuleOption: (function() {
    const ruleId = this.get('model.rule_id');
    const options = this.get('ruleOptions');
    return _.find(options, (option) => option.id === ruleId);
  }).property('model.rule_id'),

  actions: {

    openRuleModal(ruleData) {
      return this.get('targetingController').send('openRuleModal', ruleData);
    },

    selectTargetingRule(rule) {
      this.set('model.rule_id', rule.id);
    }
  }
});
