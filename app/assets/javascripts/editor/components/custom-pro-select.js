HelloBar.CustomProSelectComponent = Ember.Component.extend({

  isOpen: false,
  tabindex: -1,

  classNames: ['custom-select-wrapper'],
  classNameBindings: ['isOpen:is-open'],
  attributeBindings: ['tabindex'], // to make component focusable

  _setSelectedOption: ( function () {
    return this.set('currentChoice', this.get('options').findBy('key', this.get('choice')));
  }).observes('choice').on('init'),

  focusOut() {
    return this.set("isOpen", false);
  },

  click() {
    return this.toggleProperty("isOpen");
  },

  actions: {

    optionSelected(option) {
      return this.sendAction('action', option);
    }
  }
});

//-----------  Custom Select Child Views  -----------#

HelloBar.CustomSelectOption = Ember.View.extend({

  classNames: ['custom-select-option'],

  click() {
    return this.get('parentView').send('optionSelected', this.get('option'));
  }
});
