import Ember from 'ember';

export default Ember.Component.extend({

  tagName: 'ul',

  classNames: ['social-select'],
  classNameBindings: ['isSelected'],

  selection: null,
  selectionInProgress: false,

  isSelected: function () {
    return !!this.get('selection') && !this.get('selectionInProgress');
  }.property('selection', 'selectionInProgress'),

  init() {
    this._super();
    this.set('selectionInProgress', !this.get('selection'));
  },

  actions: {
    clearSocialSelection () {
      this.set('selectionInProgress', true);
    }
  }

});
