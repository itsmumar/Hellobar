import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  targetingController: Ember.inject.controller('targeting'),

  ruleOptions: function() {
    const options = this.get('targetingController.ruleOptions');
    return options || [];
  }.property('targetingController.ruleOptions'),

  selectedRuleOption: (function() {
    const ruleId = this.get('model.rule_id');
    const options = this.get('ruleOptions');
    const selectedOption = _.find(options, (option) => option.id === ruleId);
    return selectedOption || options[0];
  }).property('model.rule_id', 'ruleOptions'),

  actions: {

    openRuleModal(ruleData) {
      return this.get('targetingController').send('openRuleModal', ruleData);
    },

    selectTargetingRule(rule) {
      this.set('model.rule_id', rule.id);
    }
  }
});
