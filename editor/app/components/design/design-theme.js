import Ember from 'ember';
var count = 0;

export default Ember.Component.extend({

  classNames: ['design-step'],

  bus: Ember.inject.service(),
  theming: Ember.inject.service(),

  templateName: Ember.computed.alias('model.theme.name'),
  userIsNew: Ember.computed.equal('model.settings.new_user', true),
  isNotRendered: true,


  actions: {
    changeTheme () {
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'preview/containers/theming/theme-tile-grid',
        componentOptions: {
          elementType: this.get('model.type')
        }
      });
    }
  },  init() {
  this._super(...arguments);
  count = count + 1;
  },
  willRender() {
    this._super(...arguments);
    if(count > 1){
      this.set('isNotRendered', false);
    }
  }
});
