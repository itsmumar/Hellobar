import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['contact-list-select'],
  classNameBindings: ['hasContactList:has-list'],

  hasContactList: Ember.computed.gt('options.length', 0),

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

    newList() {
      this.sendAction('editList');
    },

    editList() {
      this.sendAction('editList', this.get('calculatedSelectedOption.id'));
    },

    selectOption(option) {
      if (option && option.id) {
        this.sendAction('setList', option.id);
      }
    }
  }
});
