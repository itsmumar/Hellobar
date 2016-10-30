HelloBar.ContactListSelectComponent = Ember.Component.extend({

  classNames: ['contact-list-wrapper'],
  classNameBindings: ['isOpen:is-open', 'hasContactList:has-list'],
  attributeBindings: ['tabindex'], // to make component focusable

  tabindex: -1,
  isOpen: false,
  hasContactList: Ember.computed.gt('options.length', 0),

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

  focusOut() {
    return this.set('isOpen', false);
  },

  actions: {

    toggleOpen() {
      return this.toggleProperty('isOpen');
    },

    newList() {
      return this.sendAction('editList');
    },

    editList() {
      return this.sendAction('editList', this.get('selectedList.id'));
    },

    listSelected(value) {
      this.sendAction('setList', value);
      return this.set('value', value);
    }
  }
});

//-----------  Contact List Child Views  -----------#

HelloBar.ContactListOption = Ember.View.extend({

  classNames: ['contact-list-option'],

  click() {
    return this.get('parentView').send('listSelected', this.get('option.id'));
  }
});
