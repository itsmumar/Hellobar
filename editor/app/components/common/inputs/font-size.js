import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['font-size-input'],

  formattedValue: function () {
    return `${ this.get('size') }px`;
  }.property('value'),

  actions: {
    increment () {
      this.incrementProperty('size');
    },

    decrement () {
      this.decrementProperty('size');
    }
  }
});
