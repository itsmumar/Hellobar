/* globals DelayTooltipModal */

import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({
  elementTrigger: Ember.inject.service(),

<<<<<<< HEAD
  triggerOptions: Ember.computed.alias('elementTrigger.options'),
=======
  triggerOptions: [
    {value: 'wait-5', label: '5 second delay'},
    {value: 'wait-10', label: '10 second delay'},
    {value: 'wait-30', label: '30 second delay'},
    {value: 'wait-60', label: '60 second delay'},
    {value: 'scroll-some', label: 'After scrolling a little'},
    {value: 'scroll-middle', label: 'After scrolling to middle'},
    {value: 'scroll-to-bottom', label: 'After scrolling to bottom'},
    {value: 'exit-intent', label: 'User intends to leave'}
  ],
>>>>>>> removing the immediately option from view trigger select

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
