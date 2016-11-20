import Ember from 'ember';

export default Ember.Component.extend({

  componentRegistry: Ember.inject.service(),

  classNames: ['tab-pane'],
  classNameBindings: ['isActive:active'],
  attributeBindings: ['onSelection'],

  isActive: (function () {
    //const parentComponent = this.getParentComponent();
    //return this.get('elementId') === parentComponent.get('activePaneId');
    return true;
  }).property('elementId', 'parentView.activePaneId'), // TODO refactor parentView.activePaneId here

  didInsertElement() {
    Ember.run.next(() => {
      const parentComponent = this.getParentComponent();
      parentComponent.get('panes').pushObject({
        paneId: this.get('elementId'),
        name: this.get('name'),
        action: this.get('onSelection')
      });
      if (parentComponent.get(`model.${parentComponent.get('currentTabNameAttribute')}`) === this.get('name')) {
        parentComponent.setActivePane(this.get('elementId'), this.get('name'));
      }
      if (this.get('parentView.activePaneId') === null) {
        parentComponent.setActivePane(this.get('elementId'), this.get('name'));
      }
    }, 0);
  },

  getParentComponent() {
    const parentRegistrationId = this.$().closest('.js-tab-view[data-registration-id]').attr('data-registration-id');
    return this.get('componentRegistry').getByRegistrationId(parentRegistrationId);
  }

});
