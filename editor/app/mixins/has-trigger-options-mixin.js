/* globals DelayTooltipModal */

import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({
  elementTrigger: Ember.inject.service(),

  selectedTriggerOption: function() {
    const viewCondition = this.get('model.view_condition');
    return _.find(
      this.get('elementTrigger.options'),
      (option) => option.value === viewCondition
    );
  }.property('model.view_condition'),

  actions: {
    popDelayTootlipModal() {
      return new DelayTooltipModal().open();
    },

    selectTrigger(triggerOption) {
      this.set('model.view_condition', triggerOption.value);
    }
  }
});
