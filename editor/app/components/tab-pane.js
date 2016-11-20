import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['tab-pane'],
  classNameBindings: ['isActive:active'],
  attributeBindings: ['onSelection'],
  isActive: (function () {
    return this.get('elementId') === this.get('parentView.activePaneId');
  }).property('elementId', 'parentView.activePaneId'),
  didInsertElement() {
    this.get('parentView.panes').pushObject({
      paneId: this.get('elementId'),
      name: this.get('name'),
      action: this.get('onSelection')
    });
    if (this.get(`parentView.model.${this.get('parentView.currentTabNameAttribute')}`) === this.get('name')) {
      this.get('parentView').setActivePane(this.get('elementId'), this.get('name'));
    }
    if (this.get('parentView.activePaneId') === null) {
      this.get('parentView').setActivePane(this.get('elementId'), this.get('name'));
    }
  }
});
