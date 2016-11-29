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

  init() {
    if (this.get('hasContactList') && Ember.isEmpty(this.get('value'))) {
      this.sendAction('setList', this.get('options.firstObject.id'));
    }
    return this._super();
  },

  _setSelectedList: ( function () {
    let value = this.get('value') || 0;
    let list = this.get('options').findBy('id', value);
    return this.set('selectedList', list || this.get('options.firstObject'));
  }).observes('value').on('init'),

  actions: {

    newList() {
      return this.sendAction('editList');
    },

    editList() {
      return this.sendAction('editList', this.get('selectedList.id'));
    },

    selectOption(option) {
      option && option.id && this.sendAction('setList', option.id);
    }
  }
});

