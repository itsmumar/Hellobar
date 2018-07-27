import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['collapse'],
  classNameBindings: ['show'],

  show: false,

  caretIcon: function () {
    return this.get('show') ? 'caret-down' : 'caret-left';
  }.property('show'),

  actions: {
    toggle () {
      this.toggleProperty('show');
    }
  }
});
