import Ember from 'ember';

export default Ember.Component.extend({
  /**
   * @property {object} Application model
   */
  model: null,

  theming: Ember.inject.service(),
  elementPlacement: Ember.inject.service(),
  elementTrigger: Ember.inject.service(),

  themeSelectionInProgress: false,

  type: Ember.computed.alias('model.type'),

  isAlert: Ember.computed.equal('type', 'Alert'),
  isBar: Ember.computed.equal('type', 'Bar'),
  isModal: Ember.computed.equal('type', 'Modal'),
  isSlider: Ember.computed.equal('type', 'Slider'),
  isTakeover: Ember.computed.equal('type', 'Takeover'),

  onlyTopBarStyleIsAvailable: Ember.computed.equal('model.element_subtype', 'call'),
  notOnlyTopBarStyleIsAvailable: Ember.computed.not('onlyTopBarStyleIsAvailable'),

  actions: {
    select(type) {
      this.set('type', type);
      this.set('model.theme_changed', true);
      this.get('theming').resetThemeIfNeeded(type);
      this.get('theming').applyCurrentTheme();
      this.get('elementPlacement').updatePlacement(this, type);
      this.get('elementTrigger').updateTrigger(this, type);
    }
  }
});
