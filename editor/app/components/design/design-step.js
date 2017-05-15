import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['design-step'],

  theming: Ember.inject.service(),

  currentThemeIsGeneric: Ember.computed.alias('theming.currentThemeIsGeneric'),
  currentThemeIsTemplate: Ember.computed.alias('theming.currentThemeIsTemplate'),

  isCustom: Ember.computed.equal('model.type', 'Custom'),

  elementTypeIsAlert: Ember.computed.equal('model.type', 'Alert'),
  elementTypeIsNotAlert: Ember.computed.not('elementTypeIsAlert'),


  // TODO REFACTOR -> theming or modelLogic
  // Site Element Theme Properties
  themeChanged: Ember.observer('currentTheme', function () {
      Ember.run.next(this, function () {
          this.setProperties({
            'model.image_placement': this.getImagePlacement()
          });
        }
      );
    }
  ),

  shouldShowThankYouEditor: Ember.computed.equal('model.element_subtype', 'email')

});
