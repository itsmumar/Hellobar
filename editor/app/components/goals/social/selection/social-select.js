import Ember from 'ember';

export default Ember.Component.extend({

  tagName: 'ul',

  classNames: ['social-select'],
  classNameBindings: ['isSelected'],

  selection: null,

  isSelected: Ember.computed.notEmpty('selection')

});
