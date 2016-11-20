import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['contact-list-option'],

  click() {
    return this.get('parentView').send('listSelected', this.get('option.id'));
  }
});
