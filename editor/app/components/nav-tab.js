import Ember from 'ember';

export default Ember.Component.extend({
  tagName: 'a',
  classNames: ['nav-pill'],
  classNameBindings: ['isActive:active'],
  attributeBindings: ['onSelection'],
  isActive: (function () {
    return this.get('paneId') === this.get('parentView.activePaneId');
  }).property('paneId', 'parentView.activePaneId'),
  click() {
    this.get('parentView').setActivePane(this.get('paneId'), this.get('name'));
    this.sendAction('doTabSelected', this.get('onSelection'));
  },

  doTabSelected: 'doTabSelected'
});
