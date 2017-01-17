import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['custom-pro-select'],

  selectedOption: null,

  calculatedSelectedOption: function() {
    const selectedOption = this.get('selectedOption');
    if (selectedOption) {
      return selectedOption;
    } else {
      const options = this.get('options');
      if (options && options.length > 0) {
        return options[0];
      } else {
        return null;
      }
    }
  }.property('selectedOption', 'options'),

  actions: {
    selectOption(option) {
      this.sendAction('onchange', option);
    }
  }
});

