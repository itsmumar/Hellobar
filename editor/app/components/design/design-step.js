import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['design-step'],

  theming: Ember.inject.service(),

  currentThemeIsGeneric: Ember.computed.alias('theming.currentThemeIsGeneric'),
  currentThemeIsTemplate: Ember.computed.alias('theming.currentThemeIsTemplate'),

  elementTypeIsAlert: Ember.computed.equal('model.type', 'Alert'),
  elementTypeIsNotAlert: Ember.computed.not('elementTypeIsAlert'),

  shouldShowThankYouEditor: Ember.computed.equal('model.element_subtype', 'email'),

  propertiesComponentNameForType: function() {
    const type = this.get('model.type');

    if (!type) {
      return;
    }

    return `design/${ type.toLowerCase() }/properties`;
  }.property('model.type'),

  propertiesComponentNameForGoal: function() {
    const goal = this.get('model.element_subtype');

    if (!goal) {
      return;
    }

    const componentName = goal.split('/')[0].toLowerCase();

    return `design/design-${ componentName }`;
  }.property('model.type')
});
