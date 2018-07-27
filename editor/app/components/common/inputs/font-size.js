import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['font-size-input'],

  formattedValue: function () {
    return `${ this.get('size') }px`;
  }.property('size'),

  actions: {
    increment () {
      this.incrementProperty('size');
    },

    decrement () {
      this.decrementProperty('size');
    }
  }
});
