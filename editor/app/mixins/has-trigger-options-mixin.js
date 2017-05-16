import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({

  triggerOptions: [
    {value: 'immediately', label: 'Immediately'},
    {value: 'wait-5', label: '5 second delay'},
    {value: 'wait-10', label: '10 second delay'},
    {value: 'wait-30', label: '30 second delay'},
    {value: 'wait-60', label: '60 second delay'},
    {value: 'scroll-some', label: 'After scrolling a little'},
    {value: 'scroll-middle', label: 'After scrolling to middle'},
    {value: 'scroll-to-bottom', label: 'After scrolling to bottom'},
    {value: 'exit-intent', label: 'User intends to leave'}
  ],

  selectedTriggerOption: function() {
    const viewCondition = this.get('model.view_condition');
    return _.find(this.get('triggerOptions'), (option) => option.value === viewCondition);
  }.property('model.view_condition'),

  actions: {
    popDelayTootlipModal() {
      // TODO import this class
      return new DelayTooltipModal().open();
    },

    selectTrigger(triggerOption) {
      this.set('model.view_condition', triggerOption.value);
    }
  }
});
