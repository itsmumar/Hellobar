import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['design-step'],

  bus: Ember.inject.service(),
  theming: Ember.inject.service(),

  templateName: Ember.computed.alias('model.theme.name'),

  actions: {
    changeTheme () {
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'preview/containers/theming/theme-tile-grid',
        componentOptions: {
          elementType: this.get('model.type')
        }
      });
    }
  }
});
