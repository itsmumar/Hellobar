import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['custom-select-option'],

  click() {
    return this.get('parentView').send('optionSelected', this.get('option'));
  }
});
