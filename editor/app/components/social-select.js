import Ember from 'ember';

export default Ember.Component.extend({

  init() {
    this._super(...arguments);
    console.log('social-select-option', this);
  },

  tagName: 'ul',

  classNames: ['social-select'],
  classNameBindings: ['isSelected'],

  isSelected: Ember.computed.notEmpty('selection')
});
