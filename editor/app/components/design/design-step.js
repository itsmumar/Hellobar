import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['design-step'],

  theming: Ember.inject.service(),

  currentThemeIsGeneric: Ember.computed.alias('theming.currentThemeIsGeneric'),
  currentThemeIsTemplate: Ember.computed.alias('theming.currentThemeIsTemplate'),

  isCustom: Ember.computed.equal('model.type', 'Custom'),

  elementTypeIsAlert: Ember.computed.equal('model.type', 'Alert'),
  elementTypeIsNotAlert: Ember.computed.not('elementTypeIsAlert'),

  shouldShowThankYouEditor: Ember.computed.equal('model.element_subtype', 'email')

});
